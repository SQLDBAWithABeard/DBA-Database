CREATE TABLE [dbo].[ScriptList]
(
[ScriptID] [int] NOT NULL IDENTITY(1, 1),
[ScriptName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[ScriptDecription] [nvarchar] (256) COLLATE Latin1_General_CI_AS NOT NULL,
[ScriptLocation] [nvarchar] (256) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ScriptList] ADD CONSTRAINT [PK_ScriptList] PRIMARY KEY CLUSTERED  ([ScriptID]) ON [PRIMARY]
GO
