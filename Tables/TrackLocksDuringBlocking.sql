CREATE TABLE [dbo].[TrackLocksDuringBlocking] (
    [ID]                            BIGINT        IDENTITY (1, 1) NOT NULL,
    [isolation_level]               VARCHAR (40)  NULL,
    [resource_type]                 NVARCHAR (60) NULL,
    [resource_database_id]          INT           NULL,
    [resource_associated_entity_id] BIGINT        NULL,
    [request_mode]                  NVARCHAR (60) NULL,
    [request_session_id]            INT           NULL,
    [blocking_session_id]           SMALLINT      NULL,
    [object name]                   [sysname]     NULL,
    [object descr]                  NVARCHAR (60) NULL,
    [partition id]                  BIGINT        NULL,
    [partition/page rows]           BIGINT        NULL,
    [index descr]                   NVARCHAR (60) NULL,
    [index/page container_id]       BIGINT        NULL,
    [PostedDate]                    DATETIME      DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [idx_PostedDate_TLDB]
    ON [dbo].[TrackLocksDuringBlocking]([PostedDate] ASC);

