using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;


namespace DataActivityService
{
    class Program
    {
        private static TestDataMachine TestMachine;

        public static void Main()
        {

            Console.WriteLine("*** DATA ACTIVITY SERVICE ***");

            TestMachine = new TestDataMachine();
            TestMachine.Start();

            Console.WriteLine("\n\nStopping");
        }
    }

    public class TestDataMachine
    {


        private SqlConnection centralConn;
        private SqlConnection eventConn;
        private TestControl testControl;


        string centralDataSource = Environment.GetEnvironmentVariable("CENTRAL");
        string eventlogsDataSource = Environment.GetEnvironmentVariable("EVENTLOGS");
        string taskServiceName = Environment.GetEnvironmentVariable("SERVICE_NAME");
        string taskUserPassword = Environment.GetEnvironmentVariable("SA_PASSWORD");

        public void Start()
        {

            try
            {

                centralDataSource = "tcp:" + centralDataSource;
                eventlogsDataSource = "tcp:" + eventlogsDataSource;

                Console.WriteLine($"centralDataSource={centralDataSource}");
                Console.WriteLine($"eventlogsDataSource={eventlogsDataSource}");




                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
                builder.DataSource = centralDataSource;   // update me
                builder.UserID = "sa";              // update me
                builder.Password = taskUserPassword;      // update me
                builder.ApplicationName = taskServiceName;
                builder.InitialCatalog = "fl-central";
                builder.MultipleActiveResultSets = false;


                this.centralConn = new SqlConnection(builder.ConnectionString);


                builder = new SqlConnectionStringBuilder();
                builder.DataSource = eventlogsDataSource;   // update me
                builder.UserID = "sa";              // update me
                builder.Password = taskUserPassword;      // update me
                builder.ApplicationName = taskServiceName;
                builder.InitialCatalog = "fl-eventlogs";
                builder.MultipleActiveResultSets = false;


                this.eventConn = new SqlConnection(builder.ConnectionString);



                var dbTestTimer = new Stopwatch();
                dbTestTimer.Start();

                while (dbTestTimer.ElapsedMilliseconds < 60000)
                {
                    try
                    {
                        if (this.centralConn.State != System.Data.ConnectionState.Open)
                        {
                            this.centralConn.Open();
                        }

                        if (this.eventConn.State != System.Data.ConnectionState.Open)
                        {
                            this.eventConn.Open();
                        }

                        while (!IsCentralReady())
                        {
                            System.Threading.Thread.Sleep(1000);
                        }

                        while (!IsEventDBReady())
                        {
                            System.Threading.Thread.Sleep(1000);
                        }

                        break;
                    }
                    catch(SqlException E)
                    {
                        Console.WriteLine("Databases still not up yet...");
                        System.Threading.Thread.Sleep(5000);
                    }
                }

                dbTestTimer.Stop();


                while (!GetControlValues())
                {
                    Console.WriteLine("test control values are mising...");
                    System.Threading.Thread.Sleep(3000);
                }

                // init the Athletes
                Console.WriteLine($"Initialze data on central...");

                for (var x = 0; x < testControl.StartAthleteCount; x++)
                {
                    CreateNewAthlete();
                }

                // init the Events
                Console.WriteLine($"Initialze data on eventlogs...");
                for (var x = 0; x < testControl.StartEventCount; x++)
                {
                    CreateAthleteProfileViewEvent();
                }

                Console.WriteLine($"running data activity...");

                var sw = new Stopwatch();
                sw.Start();

                var controlSw = new Stopwatch();
                controlSw.Start();

                Int32 MinuteWork = 60000;
                Int32 AthleteCreateCount = 0;
                Int32 AthleteUpdateCount = 0;
                Int32 EventCount = 0;

                System.Threading.Thread.Sleep(50);

                while (true)
                {

                    if (controlSw.ElapsedMilliseconds > 10000)
                    {
                        GetControlValues();
                        controlSw.Restart();

                        if (testControl.EnableValidationData)
                        {
                            SyncAthleteDataForValidation();
                        }
                    }

                    if (testControl.AthleteInsertRatePerMin > 0)
                    {
                        if (sw.ElapsedMilliseconds / testControl.AthleteInsertRatePerMin / 60 > AthleteCreateCount
                        && testControl.MaxAthleteCount > AthleteCreateCount)
                        {
                            CreateNewAthlete();
                            AthleteCreateCount++;
                        }
                    }


                    if (testControl.AthleteUpdateRatePerMin > 0)
                    {
                        if (sw.ElapsedMilliseconds / testControl.AthleteUpdateRatePerMin / 60 > AthleteUpdateCount)
                        {
                            UpdateAthlete();
                            AthleteUpdateCount++;
                        }
                    }


                    if (testControl.EventRatePerMin > 0)
                    {
                        if (sw.ElapsedMilliseconds / (testControl.EventRatePerMin / 60) > EventCount
                        && testControl.MaxEventCount > EventCount)
                        {
                            CreateAthleteProfileViewEvent();
                            EventCount++;
                        }
                    }


                    

                }





                Console.WriteLine($"Done!");
            }

            catch (Exception e)
            {
                Console.WriteLine(e.ToString());
            }

        }

        public class TestControl
        {
            public Int32 StartAthleteCount { get; set; }
            public Int32 MaxAthleteCount { get; set; }
            public Int32 AthleteInsertRatePerMin { get; set; }
            public Int32 AthleteUpdateRatePerMin { get; set; }
            public Int32 StartEventCount { get; set; }
            public Int32 MaxEventCount { get; set; }
            public Int32 EventRatePerMin { get; set; }
            public bool EnableValidationData { get; set; }
        }

        public bool GetControlValues()
        {
            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            using (var command = new SqlCommand(@"
select top 1 StartAthleteCount 
    , MaxAthleteCount
    , AthleteInsertRatePerMin
    , AthleteUpdateRatePerMin
    , StartEventCount
    , MaxEventCount
    , EventRatePerMin 
    , EnableValidationData
from testControl 
order by LatestOffset desc ", this.centralConn))
            {
                using (var reader = command.ExecuteReader())
                {
                    if (!reader.HasRows)
                    {
                        return false;
                    }

                    while (reader.Read())
                    {
                        this.testControl = new TestControl
                        {
                            StartAthleteCount = reader.GetInt32(0),
                            MaxAthleteCount = reader.GetInt32(1),
                            AthleteInsertRatePerMin = reader.GetInt32(2),
                            AthleteUpdateRatePerMin = reader.GetInt32(3),
                            StartEventCount = reader.GetInt32(4),
                            MaxEventCount = reader.GetInt32(5),
                            EventRatePerMin = reader.GetInt32(6),
                            EnableValidationData = reader.GetBoolean(7)
                        };

                        break;
                    }

                    return true;
                }
            }
        }



        public void CreateNewAthlete()
        {

            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            using (var command = new SqlCommand(@"dbo.CreateNewAthlete", this.centralConn))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.ExecuteNonQuery();
            }
        }

        public void UpdateAthlete()
        {
            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            using (var command = new SqlCommand(@"dbo.UpdateAthlete", this.centralConn))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.ExecuteNonQuery();
            }
        }

        public Int32 GetRandomAthlete()
        {
            Int32 AthleteId = 0;

            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            using (var command = new SqlCommand(@"select top 1 AthleteId from dbo.Athlete order by newid()", this.centralConn))
            {
                using (var reader = command.ExecuteReader())
                {
                    if (!reader.HasRows)
                    {
                        return AthleteId;
                    }

                    while (reader.Read())
                    {
                        AthleteId = reader.GetInt32(0);

                        break;
                    }
                }
            }
            return AthleteId;
        }

        public void CreateAthleteProfileViewEvent()
        {

            var AthleteId = GetRandomAthlete();

            if (this.eventConn.State != System.Data.ConnectionState.Open)
            {
                this.eventConn.Open();
            }

            using (var command = new SqlCommand(@"dbo.CreateAthleteProfileViewEvent", this.eventConn))
            {
                command.CommandType = CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@AthleteId", AthleteId);
                command.ExecuteNonQuery();
            }
        }


        public bool IsCentralReady()
        {
            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            using (var command = new SqlCommand(@"select object_id('dbo.UpdateAthlete')", this.centralConn))
            {
                using (var reader = command.ExecuteReader())
                {
                    if (!reader.HasRows)
                    {
                        return false;
                    }

                    while (reader.Read())
                    {
                        break;
                    }
                }
            }
            return true;
        }

        public bool IsEventDBReady()
        {
            if (this.eventConn.State != System.Data.ConnectionState.Open)
            {
                this.eventConn.Open();
            }

            using (var command = new SqlCommand(@"select object_id('dbo.CreateAthleteProfileViewEvent')", this.eventConn))
            {
                using (var reader = command.ExecuteReader())
                {
                    if (!reader.HasRows)
                    {
                        return false;
                    }

                    while (reader.Read())
                    {
                        break;
                    }
                }
            }
            return true;
        }



        public void TruncateAthleteDataForValidation()
        {
            if (this.eventConn.State != System.Data.ConnectionState.Open)
            {
                this.eventConn.Open();
            }

            using (var command = new SqlCommand(@"truncate table dbo.Athlete", this.eventConn))
            {
                command.ExecuteNonQuery();
            }
        }


        private void SyncAthleteDataForValidation()
        {

            if (this.eventConn.State != System.Data.ConnectionState.Open)
            {
                this.eventConn.Open();
            }

            if (this.centralConn.State != System.Data.ConnectionState.Open)
            {
                this.centralConn.Open();
            }

            try
            {

                string sql = $"select AthleteId, Sport, recruitingClassYear from dbo.Athlete";

                string destinationTableWithSchema = string.Format("[{0}].[{1}]", "dbo", "Athlete");

                // get data from source table as SqlDataReader
                SqlCommand commandSourceData = new SqlCommand(sql, this.centralConn);
                commandSourceData.CommandTimeout = 300;
                using (SqlDataReader reader = commandSourceData.ExecuteReader())
                {
                    using (SqlBulkCopy bulkCopy = new SqlBulkCopy(this.eventConn))
                    {

                        var totalRowsCopied = 0L;

                        bulkCopy.DestinationTableName = destinationTableWithSchema;
                        // when is true, SqlBulkCopy read from a IDataReader object using SequentialAccess,
                        // optimizing memory usage instead of loads all the data returned into memory before
                        // sending it to SQL Server
                        bulkCopy.EnableStreaming = true;

                        // number of seconds for the operation complete before it times out
                        bulkCopy.BulkCopyTimeout = 360;
                        // number of rows in each batch. At the end of each batch, the rows int the batch
                        // are sent to the server
                        bulkCopy.BatchSize = 1000;

                        TruncateAthleteDataForValidation();

                        bulkCopy.WriteToServer(reader);

                    }
                }

            }

            catch (Exception)
            {
                throw;
            }

        }



    }
}