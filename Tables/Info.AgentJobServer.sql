CREATE TABLE [Info].[AgentJobServer]
(
[AgentJobServerID] [int] NOT NULL IDENTITY(1, 1),
[Date] [datetime] NOT NULL,
[InstanceID] [int] NOT NULL,
[NumberOfJobs] [int] NOT NULL,
[SuccessfulJobs] [int] NOT NULL,
[FailedJobs] [int] NOT NULL,
[DisabledJobs] [int] NOT NULL,
[UnknownJobs] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[AgentJobServer] ADD CONSTRAINT [PK_Info.AgentJobServer] PRIMARY KEY CLUSTERED  ([AgentJobServerID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20150927-095740] ON [Info].[AgentJobServer] ([Date]) INCLUDE ([DisabledJobs], [FailedJobs], [InstanceID], [NumberOfJobs], [SuccessfulJobs], [UnknownJobs]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_InstanceID_JObs] ON [Info].[AgentJobServer] ([InstanceID]) INCLUDE ([DisabledJobs], [FailedJobs], [NumberOfJobs], [SuccessfulJobs], [UnknownJobs]) ON [PRIMARY]
GO
ALTER TABLE [Info].[AgentJobServer] ADD CONSTRAINT [FK_Info.AgentJobServer_InstanceList] FOREIGN KEY ([InstanceID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
