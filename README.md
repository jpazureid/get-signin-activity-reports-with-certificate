# Get sign-in activity reports with certificate
Shows how to download sign-in activity log on Azure AD using AcquireTokeAsync method with PowerShell

PowerShell スクリプトで Microsoft Graph API および証明書を利用して Azure AD のサインイン アクティビティ レポートを csv 形式で取得する方法を紹介します。

平文のキーではなく証明書を用いたトークン取得を推奨しております。以下に一連の手順をおまとめしましたので、参考としていただければ幸いです。大まかに 3 つの手順に分けて解説いたします。

## 認証に使用する証明書の準備

今回は上述のとおり、トークン取得に証明書を用います。これは、これまでの平文のキーを用いる方法よりもセキュリティ的に強力であり、弊社としても推奨している方法です。CreateAndExportCert.ps1 を実行すると、自己署名証明書が生成され、ユーザーの証明書ストア (個人) に格納します。さらに、公開鍵を .cer ファイルでカレント ディレクトリに出力します。

## 処理に必要なライブラリを nuget で取得するスクリプト

証明書を用いたトークン取得処理はライブラリを用いて行います。処理に必要なライブラリを nuget で取得します。GetAdModuleByNuget.ps1 を実行ください。本スクリプトを実行すると、実行フォルダー配下にフォルダーができ、Microsoft.IdentityModel.Clients.ActiveDirectory.dll などのファイルが保存されます。

## サインイン ログを取得するスクリプト

証明書の準備および実行に必要なライブラリの準備が整いましたら、以下の手順で、アプリケーションおよびスクリプトを準備します。

まず、以下のドキュメントに記載された手順に従って、アプリケーションを登録し、"構成設定を収集する" に従ってドメイン名とクライアント ID を取得します。

Azure AD Reporting API にアクセスするための前提条件
https://docs.microsoft.com/ja-jp/azure/active-directory/active-directory-reporting-api-prerequisites-azure-portal

続いて、GetSigninReportsWithCert.ps1 ファイルを開き、以下の 3 行を確認した結果に合わせて変更します。

```powershell
$tenantId = "yourtenant.onmicrosoft.com"
$clientID = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
$thumprint = "0123456789ABCDEF0123456789ABCDEF01234567"
```

最後に、GetSigninReportsWithCert.ps1 を実行します。これによりサインイン アクティビティ レポートを csv ファイルとして取得できます。
