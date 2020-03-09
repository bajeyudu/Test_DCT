CREATE TABLE [dbo].[CaptureErrorLogs] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [LogDate]     DATETIME      NULL,
    [ProcessInfo] VARCHAR (255) NULL,
    [Text]        VARCHAR (MAX) NULL
);

