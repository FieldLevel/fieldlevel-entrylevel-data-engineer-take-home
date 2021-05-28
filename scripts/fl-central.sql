CREATE DATABASE [fl-central]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'fl-central', FILENAME = N'/var/opt/mssql/data/fl-central.mdf' , SIZE = 20480KB , MAXSIZE = 1024000KB , FILEGROWTH = 51200KB )
 LOG ON 
( NAME = N'fl-central_log', FILENAME = N'/var/opt/mssql/data/fl-central_log.ldf' , SIZE = 8192KB , MAXSIZE = 204800KB , FILEGROWTH = 20480KB )
GO
ALTER DATABASE [fl-central] SET COMPATIBILITY_LEVEL = 150
GO
ALTER DATABASE [fl-central] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [fl-central] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [fl-central] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [fl-central] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [fl-central] SET ARITHABORT OFF 
GO
ALTER DATABASE [fl-central] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [fl-central] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [fl-central] SET AUTO_CREATE_STATISTICS OFF
GO
ALTER DATABASE [fl-central] SET AUTO_UPDATE_STATISTICS OFF 
GO
ALTER DATABASE [fl-central] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [fl-central] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [fl-central] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [fl-central] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [fl-central] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [fl-central] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [fl-central] SET  DISABLE_BROKER 
GO
ALTER DATABASE [fl-central] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [fl-central] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [fl-central] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [fl-central] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [fl-central] SET  READ_WRITE 
GO
ALTER DATABASE [fl-central] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [fl-central] SET  MULTI_USER 
GO
ALTER DATABASE [fl-central] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [fl-central] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [fl-central] SET DELAYED_DURABILITY = DISABLED 
GO
USE [fl-central]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary;
GO
USE [fl-central]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [fl-central] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO






IF NOT EXISTS ( select 1 from sys.tables where name = 'Athlete' )
begin
    CREATE TABLE dbo.Athlete(
	    athleteId int NOT NULL identity(1,1) ,
        athleteFirstName nvarchar(100) not null ,
        athleteMiddleName nvarchar(100) null ,
        athleteLastName nvarchar(100) not null , 
        sport nvarchar(50) not null ,
        gender char(1) not null ,
	    recruitingClassYear smallint NULL,
	    enrollmentAcademicLevel tinyint NULL,
	    plannedCollegeMajor nvarchar(50) NULL,
	    height decimal(5, 2) NULL,
	    weight decimal(5, 2) NULL,
	    promotionalCoverLetter nvarchar(max) NULL,
	    isMidYearTransfer bit NULL,
	    highschoolGraduationYear int NULL,
	    hobbiesAndInterests nvarchar(4000) NULL,
	    satComposite nvarchar(10) NULL,
	    satVerbal nvarchar(10) NULL,
	    satMath nvarchar(10) NULL,
	    satWriting nvarchar(10) NULL,
	    actComposite nvarchar(10) NULL,
	    scoutingNotes nvarchar(max) NULL,
	    commitmentLevel tinyint NULL,
	    recruitingNotes nvarchar(max) NULL,
	    recommendedByUserId int NULL,
	    gpa decimal(3, 2) NULL,
        latestOffset bigint not null ,
        createDate datetime2 not null ,
        modifiedDate datetime2 not null ,
        constraint pk_Athlete primary key nonclustered (athleteId) with ( data_compression=page) ,
        constraint uq_Athlete unique clustered ( latestOffset) with (data_compression=page) 
    ) 
END 
GO

IF NOT EXISTS ( select 1 from sys.sequences where name = 'AthleteOffset' )
begin
    CREATE SEQUENCE dbo.AthleteOffset
     AS [bigint]
     START WITH 200000000
     INCREMENT BY 1
     MINVALUE -9223372036854775808
     MAXVALUE 9223372036854775807
     CACHE  50000 

end
GO



CREATE OR ALTER PROCEDURE dbo.CreateNewAthlete 
as

set nocount on
set xact_abort on

declare @athleteId int ,
    @athleteFirstName nvarchar(100) ,
    @athleteMiddleName nvarchar(100)  ,
    @athleteLastName nvarchar(100) , 
    @sport nvarchar(50) ,
    @gender char(1) = 'M' ,
	@recruitingClassYear smallint = 2026 ,
	@enrollmentAcademicLevel tinyint,
	@plannedCollegeMajor nvarchar(50),
	@height decimal(5, 2) = 70 ,
	@weight decimal(5, 2) = 150 ,
	@promotionalCoverLetter nvarchar(max) ,
	@isMidYearTransfer bit ,
	@highschoolGraduationYear int ,
	@hobbiesAndInterests nvarchar(4000) ,
	@satComposite nvarchar(10) ,
	@satVerbal nvarchar(10) ,
	@satMath nvarchar(10) ,
	@satWriting nvarchar(10) ,
	@actComposite nvarchar(10) ,
	@scoutingNotes nvarchar(max) ,
	@commitmentLevel tinyint ,
	@recruitingNotes nvarchar(max) ,
	@recommendedByUserId int ,
	@gpa decimal(3, 2) ,
    @latestOffset bigint 



declare @sports table ( sport nvarchar(50) not null  primary key )
insert into @sports values 
 ( 'Soccer' )
,( 'Baseball' )
,( 'Waterpolo' )
,( 'Football' )
,( 'Volleyball' )
,( 'Basketball' )
,( 'Lacrosse' )
,( 'Tennis' )
,( 'Hockey' )
,( 'Golf' )


declare @GivenNames table ( GivenName nvarchar(100) not null primary key , gender char(1) not null ) 
insert into @GivenNames values 
 ( 'Fred', 'M' )
,( 'John', 'M' )
,( 'Tony', 'M' )
,( 'Tom', 'M' )
,( 'Mitchell', 'M' )
,( 'David', 'M' )
,( 'Daniel', 'M' )
,( 'Simon', 'M' )
,( 'James', 'M' )
,( 'Anton', 'M' )
,( 'Steven', 'M' )
,( 'Adam', 'M' )
,( 'Jim', 'M' )


,( 'Chris', 'B' )
,( 'Pat', 'B' )
,( 'Sam', 'B' )
,( 'Kelly', 'B' )


,( 'Jennifer', 'F' )
,( 'Louise', 'F' )
,( 'Amy', 'F' )
,( 'Michelle', 'F' )
,( 'Danielle', 'F' )
,( 'Tina', 'F' )
,( 'Allison', 'F' )
,( 'Kate', 'F' )
,( 'Catherine', 'F' )
,( 'Linda', 'F' )
,( 'Liz', 'F' )
,( 'Sara', 'F' )
,( 'Brenda', 'F' )
,( 'Marcia', 'F' )
,( 'Tracy', 'F' )


declare @lastNames table ( LastName nvarchar(100) not null )
insert into @lastNames  values
 ('Smith')
,('Johnson')
,('Williams')
,('Brown')
,('Jones')
,('Garcia')
,('Miller')
,('Davis')
,('Rodriguez')
,('Martinez')
,('Hernandez')
,('Lopez')
,('Gonzalez')
,('Wilson')
,('Anderson')
,('Thomas')
,('Taylor')
,('Moore')
,('Jackson')
,('Martin')
,('Lee')
,('Perez')
,('Thompson')
,('White')
,('Harris')
,('Sanchez')
,('Clark')
,('Ramirez')
,('Lewis')
,('Robinson')
,('Walker')
,('Young')
,('Allen')
,('King')
,('Wright')
,('Scott')
,('Torres')
,('Nguyen')
,('Hill')
,('Flores')
,('Green')
,('Adams')
,('Nelson')
,('Baker')
,('Hall')
,('Rivera')
,('Campbell')
,('Mitchell')
,('Carter')
,('Roberts')


declare @notes table ( note nvarchar(max) not null )
insert into @notes values 
 (N'Flei lang zwei warf ein sag der floh. Sichtbar in mi gemessen brauchte so. Gewerbe wachsam ja mu wandern anblick sagerei. Gib beeten hinter als erisch mag. Ubel es bett sage nein sa hand. Du andres gelben sa einlud em. Angenommen landsleute er so mancherlei da launischen ab geschlafen. Der wollten zur horchte schritt zwingen. 

Zu ku auskleiden aufzulosen dazwischen. Lockere ich grausam mundart hochmut ein fenster. Du aufraumen lieblinge geblendet vergesset zu. Mit bettstatt gib schneider hemdarmel unterwegs war. Sog klein das sagen kalte leise vom zwirn licht. Hellen verlie uhr kommen jungen bis freute eck schade gut. Samstag konnten gefreut nun zuliebe vor lichten. 

So zerfasert vergnugen schwachem da pa windstill kindliche liebhaben. Alles kinde hut moget kraft sagte leben gru gro als. Extra her sagte genie trost kunde leber bei wie. Kunste mu burger wiegte um pa. Mir alter mager buben tur was bin. Einfacher des verharrte bei bewirtung ihn kreiselnd. Regen se so essen genug du stirn flick pa. 

Wartete glatten konnten ansehen spruche zog gib anblick. Halboffene ob birkendose ubelnehmen ri du todesfalle ei handarbeit. Bei hinstellte hut mancherlei begleitete. Woher brief aus hosen alles tat kenne knapp. Turnhalle unendlich he bi uberhaupt verwegene liebevoll da ab schreiben. Rief nein bist mich das gewu mehr ach. Wahr tale name wu denk da fest. Gegen weste viele heute da zu es schon. 

Da du dunklen fenster stimmts ja wachter bestand bruchig te. Meinte freude so herein an ri. Essen tal eisen vor enden finde. Ku sa am da schonste schlafen launigen. Reinlich entgegen ei hinabsah du. Wunschte se gerochen brotlose fu irgendwo. 

Lustige zuliebe umwolkt sa du so wu. In fromm blick he alles im. Gerberei an feinheit brauerei es zwischen trostlos du leichter pa. Nachtun ja la wahrend schritt. Wohl auch las sie bin tate wird hier aber. Ehrbaren sa lachelte launigen gegenden brauerei vornamen ja. Uber eben wo ei in pa vers. Wahrend atemzug reichen stillen nachdem du wo sa dichten. 

Verschwand ubelnehmen so te ja aneinander es launischen. So ab lacheln spatzen em unrecht pa trocken schlank. Unbemerkt wo er barbieren mi am studieren. Gott hing es ganz er tate. Hausdacher schuchtern im ab vielleicht da ubelnehmen kuchenture. Oha dem fremden hinuber lacheln eleganz. Gar auf machte kohlen loffel tur. 

Gelandes was sprechen nebenaus kam gesichts schlafer. Kennt gutes zum nur flick. So erzahlt lustige familie melodie langsam ei lockere ja ja. Wege ei pa name wo lied bald seid ab ding. Kuchenture an stockwerke verbergend todesfalle verschwand zaunpfahle la. Tal uberwunden begleitete verbergend geh. So pa rabatten nirgends schonste em. Jungfer unrecht wahrend stickig um er taghell gemacht. 

Von grasplatz tag leuchtete lieblinge mut vergesset sudwesten einfacher. Gelernt zuliebe mi bessern gelehnt am. Harmlos tadelte offnung gefallt en ja. Wu niemand hochmut lustige ofteren ja es. Hoffnungen man dus ordentlich werkstatte jahreszeit hat. Gesprachig knabenhaft nachmittag sie hausdacher von gro. Lattenzaun um aufgespart bescheiden schuttelte flusterton la du leuchtturm. 

Nichtstun an geschickt studieren so bewirtung. Wasserkrug bi kindlichen ri frohlicher zu erhaltenen. Das trostlos allerlei konntest zwischen ein blo. Dort ich eile zaun das acht voll. Je wo es darf dies wohl wird ware. Ruhig still ihn indes ach ten ihren gutes. ' )
, (N'Concurrent uitstekend moeilijker hen dag initiatief. Leelijk twisten procede der toegang gebruik dat met far blanken. Op heuvel sakais nu dienen. Tunnels te wolfram er nu en tweeden. Are breken kosten zou omhoog lappen. Die als die wij visschers schaarsch bezwarend bevolking. 

Uit verkoopen dik dag aangelegd waaronder. Bouw over ze kwam nu na soms. In ad te verren na ruimte vijand lappen zelden deelen. Onnoodig al of tweemaal ad ze sembilan. Noch gaan worm valt wat rook tin. Verhoogd er verbouwd nu upasboom. Dan fransche die bepaalde ook centimes millioen arbeiden schaffen. 

Chinees genomen terwijl gemengd zoo zij bezocht laatste zou. Zoon waar drie in duim er duur even. Op waardoor ik veertien om minstens. Zes caoutchouc opgebracht buitendien van uitstekend rug. In tijd en vast er maar nu. Der was amboina gif eronder ton gekomen. In generaal nu in vluchten verloren behoefte te. Tot werkelijk opbrengst zij anderhalf omgewoeld olifanten mag hun wijselijk. Gesloten nu nu meesters te werkzaam beweging. Gronden nu ad opzicht witheid. 

Mee geheelen wat gas kapitaal strooien kolonist mineraal. Ook erin wie maar zien weer moet ader. Aard maar nu wier de even ik al diep. Er stof vast nu om veel daad. Personeel regeering inzamelen op de tinmijnen gebergten om mineralen. Overal al boomen af levert nu om. Werkt van dit wijze buurt dagen bezet een heele. 

Ik bouw werd kant te er geur. Ik arabische in belasting al chineesch in belovende. Nu deel arme thee in land weer ze doet al. Koopman laatste ormoezd cultuur bontste is scholen nu om ad. Een per bekoeld bersawa tijdens bronnen ver woonden voordat wat. Bezet zelve de erbij ze in werkt meest of. Op gomsoorten uitgevoerd is bescheiden geruineerd. 

Maleische om bezorgden gebrachte eindelijk vreedzame ik. Dal met vroeger fortuin procede sombere hoogere proeven hij. Personeel bereiding eindelijk krachtige arbeiders zin kan. Komst diepe bezit al de waren te. Als bij des hout zeer dat erin open veel kost. Welke dit laten tin zij goten rijst. Toe wel deed men twee geld zien dit. Of bijgeloof binnenste anderhalf eindelijk op ik. 

Wie werkten meestal men menigte bersawa. Om monopolies ad nu mislukking interesten verscholen smeltovens. Brandhout mee snelleren geschiedt bezorgden aandeelen den are. Dat treffen gomboom zekeren tot fortuin gelaten stellen. Het ziet niet lage deze het per zes ipoh. Hoogte als voeten dienen van hij gas. Er nu ad soms ze bron deze gaan. En uitkeert smelting in gevonden ze. Wij gebeurt lot systeem betreft kamarat gelegen. 

Sinds zijde in jacht ze staan al is kwala. Dragen gebrek ten mee schuld werken denken. Wij chineesch oogenblik krachtige nam behandeld. Te in ze zelfs op groei enkel. Boringen gebouwen dat dus britsche voorraad bepaalde. Nu duizend percent pagoden eronder in al. Geld voet zij deze zou kern hand niet. Zoo baksteen aandacht district stroomen ook kolonien. 

Schipbreuk ad in uitgevoerd ongebruikt en uitstekend af inboorling. Nu over te erin zeer bord vier meer. Gewonnen zuiniger men uit mijnerts tin ook. Stichting die per lot arabische zit resultaat bedroegen nabijheid. Hij hun ptolomaeus ten die archimedes kooplieden verwachten aanplanten kilometers. Sap weten ver elk tot wilde vrouw. Wij beschikken zoo uit belangrijk ingezameld verdedigen buitendien. Gevoerd waarbij vreezen oorzaak nu vervoer al. 

Ze na er bevaarbaar te dergelijke moeilijker. Zake dure jaar vele des wie. Met grooter afstand zit gronden product smelter. Vochtigen plaatsing van herhaling omgewoeld gedeelten far dit weg. Denken gerust gelukt wouden dat mei elk konden. Spelen zoo poeloe kleine hoogte als. Na de de alle daar zich of. Enkele ik en is jammer moeten. Caoutchouc spoorwegen dergelijke bescheiden te tinwinning kwartspuin in. ')
, (N'As main soit tu elle. Fenetres jet feu quarante galopent but. Souvenirs corbeille chambrees vif demeurons gaillards oui. Son les noircir eau murmure entiere abattit puisque lettres. Cime la soir ai arcs sons. Remarquent petitement ah on diplomates cathedrale. 

Fils fort art reve age bon rire eue cela. Harmonie morceaux que ils musiques fit matieres branches. Travers uns fatigue musique une nez bougres. Ame que eau age sommes naitre folles. Descendit expliquer eau oui suspendue roc reprendre indicible. Baisse nouent ici connut peu fut car parler. Alternent corbeille etendards sacrifice culbutent printemps aux bas. 

Ordonnance magistrats fanatiques prisonnier eu va et. Musique hideuse tambour chinois oh ennemis ah. Voulut et parees il la clairs ni hommes voyage contre. Fils mene ce oh tira pile epis. Hideuse circule as on apparat. Barbare maisons par peuples rit. Negation beaucoup on touchera apercoit la empilait derniere ah. Peres tot ras faite elles oncle mange. Au chez seul agir prit soir ah le peur. 

Etonnement subitement boulevards electrique le entrainait infanterie je. Cher te avez bien se suis mais le pile. Ah dentelles fourneaux atteindra suspendue ai. Cents la fumee se reste. Je toutes peuple pendus levres plutot ou un naitre se. Tricolores pic commandant paraissait cet bouquetins. 

Atteignait evidemment va me au etonnement. Mal ruches devant ebloui ecarta autres ici ils. Ils allaient horrible aux troupeau reparler. Tristes piquees noircir et ou de surpris bordees. Face he vont en fixe hors te de. Fanfares penetrer falaises air non eux barbares. Forges galons qu flamme va. 

Ni je qu avantage pretends quelques position commence poternes au. Escadrons boulevard fabriquer un sacrifice ce evocation oh. Dela rage voir chez une peu bout cuir sol. Te oh atteindra epluchant ameliorer il. Ai habitent xv tambours en entendit le trophees comptait avancent. Nous afin oh je boue quoi sang cree je. Cela chez aime est sous eue paix bout but. Peine wagon passa nid peu comme des faire. Ruer je fond me nous. 

Attachent en ah existence comprends il fourneaux or gendarmes. Xv le nations cuivres pleines extreme on on. Tout ii puis sa veut cime donc ni vite. Murmurait je la te entourage fusillade. Ramassa meurtre donjons as ah au tu. Decharnees oh qu le renferment souhaitait sa gouverneur crispation. Joyeuses six qui soutenir treteaux. 

Le preferait retombait direction si ce battirent. Republique son ses clairieres souffrance non simplement bas. Instrument ah tu oh frequentes permission me. Jeune corps qu soirs apres he. Initiez faisait et bossuee il ca. Pleines drapent eux lessive emmener pic hagarde. Menager maudite en annonce xv et oh affirma blottis. 

Cependant pas existence divergent des par conquerir prenaient des. De souffrance approchait ca compassion va. Va passent je flaques le touchee arriere ecarter. Eut flaques theatre car nid epouses mes prelude aurions. Admiration indulgence ici fanatiques poussaient atteignait jeu. Ca agissait allumait un tu lointain ignorant cornette or. Oh mains dures rente ca un court adore. Une allumait roc peu profonde qui quarante. 

On ni blanche ah fausser piquees maladie on promene. Pont agit du ah bras dela pile. Grosses luisant xv ah langage apparat. Sortir recule but forces ronfle toi ici roc. Ras peu revendre activite amoureux illumine charrues oui galopent aux. Remarquent souhaitait condamnait de oh atteignait en. Brave temps ete quand dur. Dites linge qu te bouts ne patre je. ')






declare @major table ( major nvarchar(100) not null )
insert into @major  values
 ('Math')
,('Science')
,('Biology')
,('Engineering')
,('History')
,('Arts')
,('Literature')
,('Computer Science')
,('Geology')


if rand() >= 0.5
begin
    select @gender = 'F'
end

select top 1 @athleteFirstName  = GivenName from @GivenNames where gender = @gender or gender = 'B'  order by NEWID() 
select top 1 @athleteMiddleName  = left(GivenName,1) from @GivenNames  order by NEWID() 
select top 1 @athleteLastName  = LastName from @lastNames order by NEWID() 
select top 1 @sport  = sport from @sports  order by NEWID() 


select @recruitingClassYear = @recruitingClassYear - cast( ( rand() * 10 ) as int ) % 6

select @enrollmentAcademicLevel = cast( ( rand() * 10 ) as int ) % 6
select top 1 @plannedCollegeMajor = major from @major order by NEWID() 

select @height = @height - cast( ( rand() * 10 ) as int ) % 6 + cast( ( rand() * 10 ) as int ) % 6
select @weight  = @weight  - cast( ( rand() * 10 ) as int ) % 15 + cast( ( rand() * 10 ) as int ) % 20 
select top 1 @promotionalCoverLetter = note from @notes order by newid() 

if rand() >= 0.91
begin
    select @isMidYearTransfer = 1
end

select @highschoolGraduationYear = @recruitingClassYear -1 
select top 1 @hobbiesAndInterests = left( note , 400 ) from @notes order by newid() 
select @satComposite = cast( cast( ( rand() * 1400 ) as int ) as nvarchar(10))
select @satVerbal = cast( cast( ( rand() * 800 ) as int ) as nvarchar(10))
select @satMath = cast( cast( ( rand() * 800 ) as int ) as nvarchar(10))
select @satWriting  = '0'
select @actComposite = cast( cast( ( rand() * 1400 ) as int ) as nvarchar(10))
select top 1 @scoutingNotes = note from @notes order by newid() 

select @commitmentLevel = 0

select top 1 @recruitingNotes = note from @notes order by newid() 


select @gpa = cast( (rand() * 4.6) as decimal(3, 2))

select @latestOffset = NEXT VALUE FOR dbo.AthleteOffset

insert into dbo.Athlete (
	athleteFirstName 
    ,athleteMiddleName
    ,athleteLastName 
    ,sport 
    ,gender 
	,recruitingClassYear 
	,enrollmentAcademicLevel 
	,plannedCollegeMajor 
	,height 
	,weight 
	,promotionalCoverLetter 
	,isMidYearTransfer 
	,highschoolGraduationYear 
	,hobbiesAndInterests 
	,satComposite 
	,satVerbal 
	,satMath 
	,satWriting 
	,actComposite 
	,scoutingNotes
	,commitmentLevel 
	,recruitingNotes 
	,recommendedByUserId 
	,gpa 
    ,latestOffset 
    ,createDate 
    ,modifiedDate)

values (@athleteFirstName 
    ,@athleteMiddleName
    ,@athleteLastName 
    ,@sport 
    ,@gender 
	,@recruitingClassYear 
	,@enrollmentAcademicLevel 
	,@plannedCollegeMajor 
	,@height 
	,@weight 
	,@promotionalCoverLetter 
	,@isMidYearTransfer 
	,@highschoolGraduationYear 
	,@hobbiesAndInterests 
	,@satComposite 
	,@satVerbal 
	,@satMath 
	,@satWriting 
	,@actComposite 
	,@scoutingNotes
	,@commitmentLevel 
	,@recruitingNotes 
	,@recommendedByUserId 
	,@gpa 
    ,@latestOffset 
    , sysutcdatetime() 
    , sysutcdatetime() )

go





CREATE OR ALTER PROCEDURE dbo.UpdateAthlete 
as

set nocount on
set xact_abort on

declare @athleteId int ,
    @athleteFirstName nvarchar(100) ,
    @athleteMiddleName nvarchar(100)  ,
    @athleteLastName nvarchar(100) , 
    @sport nvarchar(50) ,
    @gender char(1) = 'M' ,
	@recruitingClassYear smallint = 2026 ,
	@enrollmentAcademicLevel tinyint,
	@plannedCollegeMajor nvarchar(50),
	@height decimal(5, 2) = 70 ,
	@weight decimal(5, 2) = 150 ,
	@promotionalCoverLetter nvarchar(max) ,
	@isMidYearTransfer bit ,
	@highschoolGraduationYear int ,
	@hobbiesAndInterests nvarchar(4000) ,
	@satComposite nvarchar(10) ,
	@satVerbal nvarchar(10) ,
	@satMath nvarchar(10) ,
	@satWriting nvarchar(10) ,
	@actComposite nvarchar(10) ,
	@scoutingNotes nvarchar(max) ,
	@commitmentLevel tinyint ,
	@recruitingNotes nvarchar(max) ,
	@recommendedByUserId int ,
	@gpa decimal(3, 2) ,
    @latestOffset bigint 


declare @minOffset bigint , @maxOffset bigint , @delta bigint , @randAthleteOffset bigint 
select @minOffset = min( latestOffset  )
       ,@maxOffset = max( latestOffset )
from dbo.Athlete


select @delta = @maxOffset - @minOffset

select @randAthleteOffset = @minOffset + (rand() * cast( @delta as int ) )


select top 1 @athleteId=athleteId
        ,@athleteFirstName=athleteFirstName
        ,@athleteMiddleName=athleteMiddleName
        ,@athleteLastName=athleteLastName
        ,@sport=sport
        ,@gender=gender
        ,@recruitingClassYear=recruitingClassYear
        ,@enrollmentAcademicLevel=enrollmentAcademicLevel
        ,@plannedCollegeMajor=plannedCollegeMajor
        ,@height=height
        ,@weight=weight
        ,@promotionalCoverLetter=promotionalCoverLetter
        ,@isMidYearTransfer=isMidYearTransfer
        ,@highschoolGraduationYear=highschoolGraduationYear
        ,@hobbiesAndInterests=hobbiesAndInterests
        ,@satComposite=satComposite
        ,@satVerbal=satVerbal
        ,@satMath=satMath
        ,@satWriting=satWriting
        ,@actComposite=actComposite
        ,@scoutingNotes=scoutingNotes
        ,@commitmentLevel=commitmentLevel
        ,@recruitingNotes=recruitingNotes
        ,@recommendedByUserId=recommendedByUserId
        ,@gpa=gpa
from dbo.Athlete 
where latestOffset >= @randAthleteOffset 
order by latestOffset



declare @sports table ( sport nvarchar(50) not null  primary key )
insert into @sports values 
 ( 'Soccer' )
,( 'Baseball' )
,( 'Waterpolo' )
,( 'Football' )
,( 'Volleyball' )
,( 'Basketball' )
,( 'Lacrosse' )
,( 'Tennis' )
,( 'Hockey' )
,( 'Golf' )


declare @notes table ( note nvarchar(max) not null )
insert into @notes values 
 (N'Flei lang zwei warf ein sag der floh. Sichtbar in mi gemessen brauchte so. Gewerbe wachsam ja mu wandern anblick sagerei. Gib beeten hinter als erisch mag. Ubel es bett sage nein sa hand. Du andres gelben sa einlud em. Angenommen landsleute er so mancherlei da launischen ab geschlafen. Der wollten zur horchte schritt zwingen. 

Zu ku auskleiden aufzulosen dazwischen. Lockere ich grausam mundart hochmut ein fenster. Du aufraumen lieblinge geblendet vergesset zu. Mit bettstatt gib schneider hemdarmel unterwegs war. Sog klein das sagen kalte leise vom zwirn licht. Hellen verlie uhr kommen jungen bis freute eck schade gut. Samstag konnten gefreut nun zuliebe vor lichten. 

So zerfasert vergnugen schwachem da pa windstill kindliche liebhaben. Alles kinde hut moget kraft sagte leben gru gro als. Extra her sagte genie trost kunde leber bei wie. Kunste mu burger wiegte um pa. Mir alter mager buben tur was bin. Einfacher des verharrte bei bewirtung ihn kreiselnd. Regen se so essen genug du stirn flick pa. 

Wartete glatten konnten ansehen spruche zog gib anblick. Halboffene ob birkendose ubelnehmen ri du todesfalle ei handarbeit. Bei hinstellte hut mancherlei begleitete. Woher brief aus hosen alles tat kenne knapp. Turnhalle unendlich he bi uberhaupt verwegene liebevoll da ab schreiben. Rief nein bist mich das gewu mehr ach. Wahr tale name wu denk da fest. Gegen weste viele heute da zu es schon. 

Da du dunklen fenster stimmts ja wachter bestand bruchig te. Meinte freude so herein an ri. Essen tal eisen vor enden finde. Ku sa am da schonste schlafen launigen. Reinlich entgegen ei hinabsah du. Wunschte se gerochen brotlose fu irgendwo. 

Lustige zuliebe umwolkt sa du so wu. In fromm blick he alles im. Gerberei an feinheit brauerei es zwischen trostlos du leichter pa. Nachtun ja la wahrend schritt. Wohl auch las sie bin tate wird hier aber. Ehrbaren sa lachelte launigen gegenden brauerei vornamen ja. Uber eben wo ei in pa vers. Wahrend atemzug reichen stillen nachdem du wo sa dichten. 

Verschwand ubelnehmen so te ja aneinander es launischen. So ab lacheln spatzen em unrecht pa trocken schlank. Unbemerkt wo er barbieren mi am studieren. Gott hing es ganz er tate. Hausdacher schuchtern im ab vielleicht da ubelnehmen kuchenture. Oha dem fremden hinuber lacheln eleganz. Gar auf machte kohlen loffel tur. 

Gelandes was sprechen nebenaus kam gesichts schlafer. Kennt gutes zum nur flick. So erzahlt lustige familie melodie langsam ei lockere ja ja. Wege ei pa name wo lied bald seid ab ding. Kuchenture an stockwerke verbergend todesfalle verschwand zaunpfahle la. Tal uberwunden begleitete verbergend geh. So pa rabatten nirgends schonste em. Jungfer unrecht wahrend stickig um er taghell gemacht. 

Von grasplatz tag leuchtete lieblinge mut vergesset sudwesten einfacher. Gelernt zuliebe mi bessern gelehnt am. Harmlos tadelte offnung gefallt en ja. Wu niemand hochmut lustige ofteren ja es. Hoffnungen man dus ordentlich werkstatte jahreszeit hat. Gesprachig knabenhaft nachmittag sie hausdacher von gro. Lattenzaun um aufgespart bescheiden schuttelte flusterton la du leuchtturm. 

Nichtstun an geschickt studieren so bewirtung. Wasserkrug bi kindlichen ri frohlicher zu erhaltenen. Das trostlos allerlei konntest zwischen ein blo. Dort ich eile zaun das acht voll. Je wo es darf dies wohl wird ware. Ruhig still ihn indes ach ten ihren gutes. ' )
, (N'Concurrent uitstekend moeilijker hen dag initiatief. Leelijk twisten procede der toegang gebruik dat met far blanken. Op heuvel sakais nu dienen. Tunnels te wolfram er nu en tweeden. Are breken kosten zou omhoog lappen. Die als die wij visschers schaarsch bezwarend bevolking. 

Uit verkoopen dik dag aangelegd waaronder. Bouw over ze kwam nu na soms. In ad te verren na ruimte vijand lappen zelden deelen. Onnoodig al of tweemaal ad ze sembilan. Noch gaan worm valt wat rook tin. Verhoogd er verbouwd nu upasboom. Dan fransche die bepaalde ook centimes millioen arbeiden schaffen. 

Chinees genomen terwijl gemengd zoo zij bezocht laatste zou. Zoon waar drie in duim er duur even. Op waardoor ik veertien om minstens. Zes caoutchouc opgebracht buitendien van uitstekend rug. In tijd en vast er maar nu. Der was amboina gif eronder ton gekomen. In generaal nu in vluchten verloren behoefte te. Tot werkelijk opbrengst zij anderhalf omgewoeld olifanten mag hun wijselijk. Gesloten nu nu meesters te werkzaam beweging. Gronden nu ad opzicht witheid. 

Mee geheelen wat gas kapitaal strooien kolonist mineraal. Ook erin wie maar zien weer moet ader. Aard maar nu wier de even ik al diep. Er stof vast nu om veel daad. Personeel regeering inzamelen op de tinmijnen gebergten om mineralen. Overal al boomen af levert nu om. Werkt van dit wijze buurt dagen bezet een heele. 

Ik bouw werd kant te er geur. Ik arabische in belasting al chineesch in belovende. Nu deel arme thee in land weer ze doet al. Koopman laatste ormoezd cultuur bontste is scholen nu om ad. Een per bekoeld bersawa tijdens bronnen ver woonden voordat wat. Bezet zelve de erbij ze in werkt meest of. Op gomsoorten uitgevoerd is bescheiden geruineerd. 

Maleische om bezorgden gebrachte eindelijk vreedzame ik. Dal met vroeger fortuin procede sombere hoogere proeven hij. Personeel bereiding eindelijk krachtige arbeiders zin kan. Komst diepe bezit al de waren te. Als bij des hout zeer dat erin open veel kost. Welke dit laten tin zij goten rijst. Toe wel deed men twee geld zien dit. Of bijgeloof binnenste anderhalf eindelijk op ik. 

Wie werkten meestal men menigte bersawa. Om monopolies ad nu mislukking interesten verscholen smeltovens. Brandhout mee snelleren geschiedt bezorgden aandeelen den are. Dat treffen gomboom zekeren tot fortuin gelaten stellen. Het ziet niet lage deze het per zes ipoh. Hoogte als voeten dienen van hij gas. Er nu ad soms ze bron deze gaan. En uitkeert smelting in gevonden ze. Wij gebeurt lot systeem betreft kamarat gelegen. 

Sinds zijde in jacht ze staan al is kwala. Dragen gebrek ten mee schuld werken denken. Wij chineesch oogenblik krachtige nam behandeld. Te in ze zelfs op groei enkel. Boringen gebouwen dat dus britsche voorraad bepaalde. Nu duizend percent pagoden eronder in al. Geld voet zij deze zou kern hand niet. Zoo baksteen aandacht district stroomen ook kolonien. 

Schipbreuk ad in uitgevoerd ongebruikt en uitstekend af inboorling. Nu over te erin zeer bord vier meer. Gewonnen zuiniger men uit mijnerts tin ook. Stichting die per lot arabische zit resultaat bedroegen nabijheid. Hij hun ptolomaeus ten die archimedes kooplieden verwachten aanplanten kilometers. Sap weten ver elk tot wilde vrouw. Wij beschikken zoo uit belangrijk ingezameld verdedigen buitendien. Gevoerd waarbij vreezen oorzaak nu vervoer al. 

Ze na er bevaarbaar te dergelijke moeilijker. Zake dure jaar vele des wie. Met grooter afstand zit gronden product smelter. Vochtigen plaatsing van herhaling omgewoeld gedeelten far dit weg. Denken gerust gelukt wouden dat mei elk konden. Spelen zoo poeloe kleine hoogte als. Na de de alle daar zich of. Enkele ik en is jammer moeten. Caoutchouc spoorwegen dergelijke bescheiden te tinwinning kwartspuin in. ')
, (N'As main soit tu elle. Fenetres jet feu quarante galopent but. Souvenirs corbeille chambrees vif demeurons gaillards oui. Son les noircir eau murmure entiere abattit puisque lettres. Cime la soir ai arcs sons. Remarquent petitement ah on diplomates cathedrale. 

Fils fort art reve age bon rire eue cela. Harmonie morceaux que ils musiques fit matieres branches. Travers uns fatigue musique une nez bougres. Ame que eau age sommes naitre folles. Descendit expliquer eau oui suspendue roc reprendre indicible. Baisse nouent ici connut peu fut car parler. Alternent corbeille etendards sacrifice culbutent printemps aux bas. 

Ordonnance magistrats fanatiques prisonnier eu va et. Musique hideuse tambour chinois oh ennemis ah. Voulut et parees il la clairs ni hommes voyage contre. Fils mene ce oh tira pile epis. Hideuse circule as on apparat. Barbare maisons par peuples rit. Negation beaucoup on touchera apercoit la empilait derniere ah. Peres tot ras faite elles oncle mange. Au chez seul agir prit soir ah le peur. 

Etonnement subitement boulevards electrique le entrainait infanterie je. Cher te avez bien se suis mais le pile. Ah dentelles fourneaux atteindra suspendue ai. Cents la fumee se reste. Je toutes peuple pendus levres plutot ou un naitre se. Tricolores pic commandant paraissait cet bouquetins. 

Atteignait evidemment va me au etonnement. Mal ruches devant ebloui ecarta autres ici ils. Ils allaient horrible aux troupeau reparler. Tristes piquees noircir et ou de surpris bordees. Face he vont en fixe hors te de. Fanfares penetrer falaises air non eux barbares. Forges galons qu flamme va. 

Ni je qu avantage pretends quelques position commence poternes au. Escadrons boulevard fabriquer un sacrifice ce evocation oh. Dela rage voir chez une peu bout cuir sol. Te oh atteindra epluchant ameliorer il. Ai habitent xv tambours en entendit le trophees comptait avancent. Nous afin oh je boue quoi sang cree je. Cela chez aime est sous eue paix bout but. Peine wagon passa nid peu comme des faire. Ruer je fond me nous. 

Attachent en ah existence comprends il fourneaux or gendarmes. Xv le nations cuivres pleines extreme on on. Tout ii puis sa veut cime donc ni vite. Murmurait je la te entourage fusillade. Ramassa meurtre donjons as ah au tu. Decharnees oh qu le renferment souhaitait sa gouverneur crispation. Joyeuses six qui soutenir treteaux. 

Le preferait retombait direction si ce battirent. Republique son ses clairieres souffrance non simplement bas. Instrument ah tu oh frequentes permission me. Jeune corps qu soirs apres he. Initiez faisait et bossuee il ca. Pleines drapent eux lessive emmener pic hagarde. Menager maudite en annonce xv et oh affirma blottis. 

Cependant pas existence divergent des par conquerir prenaient des. De souffrance approchait ca compassion va. Va passent je flaques le touchee arriere ecarter. Eut flaques theatre car nid epouses mes prelude aurions. Admiration indulgence ici fanatiques poussaient atteignait jeu. Ca agissait allumait un tu lointain ignorant cornette or. Oh mains dures rente ca un court adore. Une allumait roc peu profonde qui quarante. 

On ni blanche ah fausser piquees maladie on promene. Pont agit du ah bras dela pile. Grosses luisant xv ah langage apparat. Sortir recule but forces ronfle toi ici roc. Ras peu revendre activite amoureux illumine charrues oui galopent aux. Remarquent souhaitait condamnait de oh atteignait en. Brave temps ete quand dur. Dites linge qu te bouts ne patre je. ')




declare @major table ( major nvarchar(100) not null )
insert into @major  values
 ('Math')
,('Science')
,('Biology')
,('Engineering')
,('History')
,('Arts')
,('Literature')
,('Computer Science')
,('Geology')



if rand() > 0.95
begin
    select top 1 @sport  = sport from @sports  order by NEWID() 
end

if rand() > 0.68
begin
    select @recruitingClassYear = @recruitingClassYear - cast( ( rand() * 10 ) as int ) % 6
end

if rand() > 0.98
begin
    select @enrollmentAcademicLevel = cast( ( rand() * 10 ) as int ) % 6
end

if rand() > 0.7
begin
    select top 1 @plannedCollegeMajor = major from @major order by NEWID() 
end

if rand() > 0.98
begin
    select @height = @height - cast( ( rand() * 10 ) as int ) % 6 + cast( ( rand() * 10 ) as int ) % 6
end

if rand() > 0.89
begin
    select @weight  = @weight  - cast( ( rand() * 10 ) as int ) % 15 + cast( ( rand() * 10 ) as int ) % 20 
end

if rand() > 0.6
begin
    select top 1 @promotionalCoverLetter = note from @notes order by newid() 
end

if rand() >= 0.85
begin
    select @isMidYearTransfer = 1
end

select @highschoolGraduationYear = @recruitingClassYear -1 



if rand() > 0.98
begin
    select top 1 @hobbiesAndInterests = left( note , 400 ) from @notes order by newid() 
end

if rand() > 0.7
begin
    select @satComposite = cast( cast( ( rand() * 1400 ) as int ) as nvarchar(10))
end

if rand() > 0.7
begin
    select @satVerbal = cast( cast( ( rand() * 800 ) as int ) as nvarchar(10))
end

if rand() > 0.7
begin
    select @satMath = cast( cast( ( rand() * 800 ) as int ) as nvarchar(10))
end


if rand() > 0.6
begin
    select @actComposite = cast( cast( ( rand() * 1400 ) as int ) as nvarchar(10))
end

if rand() > 0.5
begin
    select top 1 @scoutingNotes = note from @notes order by newid() 
end

if rand() >= 0.7
begin
    select @commitmentLevel = 1
end


if rand() > 0.5
begin
    select top 1 @recruitingNotes = note from @notes order by newid() 
end


if rand() > 0.6
begin
    select @gpa = cast( (rand() * 4.6) as decimal(3, 2))
end


select @latestOffset = NEXT VALUE FOR dbo.AthleteOffset

update dbo.Athlete 
set athleteFirstName=@athleteFirstName
    ,athleteMiddleName=@athleteMiddleName
    ,athleteLastName=@athleteLastName
    ,sport=@sport
    ,gender=@gender
    ,recruitingClassYear=@recruitingClassYear
    ,enrollmentAcademicLevel=@enrollmentAcademicLevel
    ,plannedCollegeMajor=@plannedCollegeMajor
    ,height=@height
    ,weight=@weight
    ,promotionalCoverLetter=@promotionalCoverLetter
    ,isMidYearTransfer=@isMidYearTransfer
    ,highschoolGraduationYear=@highschoolGraduationYear
    ,hobbiesAndInterests=@hobbiesAndInterests
    ,satComposite=@satComposite
    ,satVerbal=@satVerbal
    ,satMath=@satMath
    ,satWriting=@satWriting
    ,actComposite=@actComposite
    ,scoutingNotes=@scoutingNotes
    ,commitmentLevel=@commitmentLevel
    ,recruitingNotes=@recruitingNotes
    ,recommendedByUserId=@recommendedByUserId
    ,gpa=@gpa
    ,latestOffset=@latestOffset
    ,modifiedDate=sysutcdatetime()
where athleteId=@athleteId



go







IF NOT EXISTS ( select 1 from sys.tables where name = 'testControl' )
begin
    CREATE TABLE dbo.testControl(
	     StartAthleteCount int not null 
        ,MaxAthleteCount int not null 
        ,AthleteInsertRatePerMin int not null 
        ,AthleteUpdateRatePerMin int not null
        ,StartEventCount int not null 
        ,MaxEventCount int not null 
        ,EventRatePerMin int not null 
		,EnableValidationData bit not null default(0)
        ,LatestOffset bigint not null PRIMARY KEY 
    ) 
END 
GO

INSERT INTO dbo.testControl(
    StartAthleteCount 
    ,MaxAthleteCount 
    ,AthleteInsertRatePerMin 
    ,AthleteUpdateRatePerMin 
    ,StartEventCount 
    ,MaxEventCount 
    ,EventRatePerMin 
    ,LatestOffset
)
VALUES (
     1000 
    ,300000
    ,20 
    ,15
    ,100
    ,200000000
    ,500
    ,NEXT VALUE FOR dbo.AthleteOffset
 )
 GO
