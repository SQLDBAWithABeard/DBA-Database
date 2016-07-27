CREATE TABLE [Info].[SuspectPages]
(
[SuspectPageID] [int] NOT NULL IDENTITY(1, 1),
[DatabaseID] [int] NOT NULL,
[DateChecked] [datetime] NOT NULL,
[FileName] [varchar] (2000) COLLATE Latin1_General_CI_AS NOT NULL,
[Page_id] [bigint] NOT NULL,
[EventType] [nvarchar] (24) COLLATE Latin1_General_CI_AS NOT NULL,
[Error_count] [int] NOT NULL,
[last_update_date] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[SuspectPages] ADD CONSTRAINT [PK_SuspectPages] PRIMARY KEY CLUSTERED  ([SuspectPageID]) ON [PRIMARY]
GO
