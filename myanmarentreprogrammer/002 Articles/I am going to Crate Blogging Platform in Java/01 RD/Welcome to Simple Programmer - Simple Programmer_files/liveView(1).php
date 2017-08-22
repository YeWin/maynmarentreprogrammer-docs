 
				function SK_pbSekindo_84372598ad9bf5b851_firePix(src)
				{
					var scrpt = document.createElement('script');
					scrpt.setAttribute('type', 'text/javascript');
					scrpt.setAttribute('src', src);
					document.body.appendChild(scrpt);
				}
				function SK_pbSekindo_84372598ad9bf5b851_verificationCode()
				{
					var verificationCodeData = {"QC":"\/\/pixel.quantserve.com\/pixel\/p-1ZHFxK2kGG5Cz.gif?labels=publisher.20749.space.84372,adsize.970x250","Lotame":"\/\/tags.crwdcntrl.net\/c\/9559\/cc_af.js","cookieSync":"\/\/live.sekindo.com\/live\/liveCookieSync.php?source=sekindo"};
					if (verificationCodeData != null)
					{
						for(var i in verificationCodeData)
						{
							if(verificationCodeData.hasOwnProperty(i))
							{
								if (i == 'QC')
								{
									var imgEl = document.createElement('img');
									imgEl.setAttribute('src', verificationCodeData[i]);
								}
								else
								{
									SK_pbSekindo_84372598ad9bf5b851_firePix(verificationCodeData[i]);
								}
							}
						}
					}
				}

				HB_bid = {};
				HB_bid.adId = '3261e66e720117f';
				HB_bid.cpm =0;
				HB_bid.width = 970;
				HB_bid.height = 250;

				HB_bid.ad = '' + "<scr"+"ipt type=\"text/javascript\">" +
					"var w = window;"+
					"for (i = 0; i < 10; i++) {"+
					"if (w.pbjs) {"+
					"try {"+
					"cw =w;" +
					"cw.SK_pbSekindo_84372598ad9bf5b851_firePix('https://live.sekindo.com/live/liveView.php?PBTRK=1&PBSESSID=pbSekindo_84372598ad9bf5b851&adType=tag&subId=simpleprogrammer.com&reqSpace2AdId=0&ecpmValue=0&sspDescripancySpace2AdId=0&spaceId=84372&isPassBack=0&diaid=&userIpAddr=103.242.99.254&userUA=Mozilla%2F5.0+%28Windows+NT+6.3%3B+Win64%3B+x64%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Chrome%2F60.0.3112.90+Safari%2F537.36&x=970&y=250&campaignFreqCap=&campaignId=&space2AdId=&frcCst=0');"+
					"cw.SK_pbSekindo_84372598ad9bf5b851_verificationCode();" +
					"break;"+
					"} catch (e) {"+
					" continue;"+
					"}}w = w.parent;}"+
					"</scr"+"ipt>";

				try
				{
					window.pbjs.sekindoCB('3261e66e720117f', HB_bid);
				}
				catch(e){}
