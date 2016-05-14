CREATE TABLE [Info].[ServerOSInfo]
(
[ServerOSInfoID] [int] NOT NULL IDENTITY(1, 1),
[DateChecked] [datetime] NULL,
[ServerName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[DNSHostName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Domain] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[OperatingSystem] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[NoProcessors] [tinyint] NULL,
[IPAddress] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[RAM] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Info].[ServerOSInfo] ADD CONSTRAINT [PK__ServerOS__50A5926BC7005F29] PRIMARY KEY CLUSTERED  ([ServerOSInfoID]) ON [PRIMARY]
GO
