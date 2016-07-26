CREATE TABLE [Info].[DatabaseLastUsed]
(
[LastUsedID] [int] NOT NULL IDENTITY(1, 1),
[DatabaseID] [int] NOT NULL,
[ScriptRunTime] [datetime] NOT NULL,
[RebootTime] [datetime] NOT NULL,
[LasRead] [datetime] NOT NULL,
[LastWrite] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[DatabaseLastUsed] ADD CONSTRAINT [PK_DatabaseLastUsed] PRIMARY KEY CLUSTERED  ([LastUsedID]) ON [PRIMARY]
GO
ALTER TABLE [Info].[DatabaseLastUsed] ADD CONSTRAINT [FK_DatabaseLastUsed_Databases] FOREIGN KEY ([DatabaseID]) REFERENCES [Info].[Databases] ([DatabaseID])
GO
