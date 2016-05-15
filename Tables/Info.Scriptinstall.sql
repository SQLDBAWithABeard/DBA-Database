CREATE TABLE [Info].[Scriptinstall]
(
[ScriptInstallID] [int] NOT NULL IDENTITY(1, 1),
[InstanceID] [int] NOT NULL,
[HasDBAdminDB] [bit] NULL,
[OlaSP] [bit] NULL,
[HasOlaRestore] [bit] NULL,
[RestoreScript] [bit] NULL,
[HasSP_Blitz] [bit] NULL,
[HasSP_AskBrent] [bit] NULL,
[HasSP_BlitzCache] [bit] NULL,
[Hassp_BlitzIndex] [bit] NULL,
[Hassp_BlitzTrace] [bit] NULL,
[Hassp_whoisactive] [bit] NULL,
[whoisactiveagentjob] [bit] NULL,
[HasOlaJobSchedule] [bit] NULL,
[HasMatchSQLLoginsJob] [bit] NULL,
[HasSPBlitzTableJob] [bit] NULL,
[HasAskBrentToTableAgentJob] [bit] NULL,
[HasOLAPRODDC1Job] [bit] NULL,
[HasOLADEVDC1Job] [bit] NULL,
[HasOLAPRODDC2Job] [bit] NULL,
[HasOLADEVDC2job] [bit] NULL,
[AGFailoverAlerts] [bit] NULL,
[EnableDBMail] [bit] NULL,
[Add_Basic_Trace_XE] [bit] NULL,
[HasAScript] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[Scriptinstall] ADD CONSTRAINT [PK_Scriptinstall] PRIMARY KEY CLUSTERED  ([ScriptInstallID]) ON [PRIMARY]
GO
ALTER TABLE [Info].[Scriptinstall] ADD CONSTRAINT [FK_Scriptinstall_InstanceList] FOREIGN KEY ([InstanceID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
 [bit]
ALTER TABLE [Info].[Scriptinstall] ADD CONSTRAINT [FK_Scriptinstall_InstanceList] FOREIGN KEY ([InstanceID]) REFERENCES [dbo].[InstanceList] ([InstanceID])
GO
