CREATE TABLE [dbo].[TrackBlockingSessions] (
    [ID]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [spid]         SMALLINT       NULL,
    [hostname]     VARCHAR (10)   NULL,
    [database]     VARCHAR (10)   NULL,
    [program_name] VARCHAR (25)   NULL,
    [loginame]     VARCHAR (20)   NULL,
    [login_time]   VARCHAR (20)   NULL,
    [last_batch]   VARCHAR (20)   NULL,
    [cmd]          VARCHAR (20)   NULL,
    [Block]        VARCHAR (20)   NULL,
    [BlockingTSQL] NVARCHAR (MAX) NULL,
    [PostedDate]   DATETIME       DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_PostedDate_TBS]
    ON [dbo].[TrackBlockingSessions]([PostedDate] ASC);

