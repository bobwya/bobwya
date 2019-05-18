#!/bin/env awk

function fix_mozilla_kde_patch(indent)
{
	if     ((FNR == 814) && ! sub("\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ nsACString[&] aResult[)];",
				"nsCOMPtr<nsIGSettingsCollection> mProxySettings;")) {
		exit 1
	}
	else if ((FNR == 815) && ! sub("nsresult GetProxyFromGConf[(]const nsACString[&] aScheme, const nsACString[&] aHost,",
				"nsInterfaceHashtable<nsCStringHashKey, nsIGSettingsCollection>")) {
		exit 1
	}
	else if ((FNR == 816) && ! sub("\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ int32_t aPort, nsACString[&] aResult[)];",
				"mSchemeProxySettings;")) {
		exit 1
	}
	else if (FNR == 847) {
		return
	}
	else if (FNR == 851) {
		printf(" \n")
	}
	printf("%s\n", $0)
}

function fix_mozilla_nongnome_proxies_patch(indent)
{
	if     ((FNR == 12) && ! sub("[-]55,24 [+]55,27","-55,21 +55,24")) {
		exit 1
	}
	else if (((FNR >= 26) && (FNR <= 28)) || (FNR >= 37) && (FNR <= 39)) {
		return
	}
	else if ((FNR == 45) && ! sub("bool nsUnixSystemProxySettings::IsProxyMode[(]const char[*] aMode[)] [{]",
				"nsresult nsUnixSystemProxySettings::GetPACURI(nsACString\& aResult) {")) {
		exit 1
	}
	else if ((FNR == 46) && ! sub("nsAutoCString mode;","if (mProxySettings) {")) {
		exit 1
	}
	else if ((FNR == 47) && ! sub("return NS_SUCCEEDED[(]mGConf[-]>GetString[(]","  nsCString proxyMode;")) {
		exit 1
	}
	printf("%s\n", $0)
}

