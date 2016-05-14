CREATE TABLE [Info].[AgentJobDetail]
(
[AgetnJobDetailID] [int] NOT NULL IDENTITY(1, 1),
[Date] [datetime] NOT NULL,
[InstanceID] [int] NOT NULL,
[Category] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[JobName] [nvarchar] (250) COLLATE Latin1_General_CI_AS NOT NULL,
[Description] [nvarchar] (750) COLLATE Latin1_General_CI_AS NOT NULL,
[IsEnabled] [bit] NOT NULL,
[Status] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[LastRunTime] [datetime] NOT NULL,
[Outcome] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[AgentJobDetail] ADD CONSTRAINT [PK_info.AgentJobDetail] PRIMARY KEY CLUSTERED  ([AgetnJobDetailID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LastRunTime_IncludeAll] ON [Info].[AgentJobDetail] ([InstanceID], [LastRunTime]) INCLUDE ([Category], [Date], [Description], [IsEnabled], [JobName], [Outcome], [Status]) ON [PRIMARY]
GO
ALTER TABLE [Info].[AgentJobDetail] ADD CONSTRAINT [FK_info.AgentJobDetail_InstanceList] FOREIGN KEY ([InstanceID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
