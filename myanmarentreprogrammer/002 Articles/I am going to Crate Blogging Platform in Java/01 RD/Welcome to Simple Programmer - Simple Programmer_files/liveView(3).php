 
				function SK_pbSekindo_84373598ad9c0ca410_firePix(src)
				{
					var scrpt = document.createElement('script');
					scrpt.setAttribute('type', 'text/javascript');
					scrpt.setAttribute('src', src);
					document.body.appendChild(scrpt);
				}
				function SK_pbSekindo_84373598ad9c0ca410_verificationCode()
				{
					var verificationCodeData = {"DV":"https:\/\/cdn.doubleverify.com\/dvtp_src.js?ctx=2791976&cmp=2791987&sid=2015051501&plc=2015051502&num=&adid=&advid=2791977&adsrv=90&region=30&btreg=&btadsrv=&crt=&crtname=&chnl=&unit=&pid=&uid=&tagtype=&dvtagver=6.1.src&sr=20&DVP_PUBLISHER=20749&DVP_SPACE=84373&DVP_SELLER=&DVP_PLACEMENT=simpleprogrammer.com&DVP_SUBID=simpleprogrammer.com&turl=simpleprogrammer.com","QC":"\/\/pixel.quantserve.com\/pixel\/p-1ZHFxK2kGG5Cz.gif?labels=publisher.20749.space.84373,adsize.300x250","Lotame":"\/\/tags.crwdcntrl.net\/c\/9559\/cc_af.js","cookieSync":"\/\/live.sekindo.com\/live\/liveCookieSync.php?source=sekindo"};
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
									SK_pbSekindo_84373598ad9c0ca410_firePix(verificationCodeData[i]);
								}
							}
						}
					}
				}

				HB_bid = {};
				HB_bid.adId = '30a7a3d837d740b';
				HB_bid.cpm =0;
				HB_bid.width = 300;
				HB_bid.height = 250;

				HB_bid.ad = '' + "<scr"+"ipt type=\"text/javascript\">" +
					"var w = window;"+
					"for (i = 0; i < 10; i++) {"+
					"if (w.pbjs) {"+
					"try {"+
					"cw =w;" +
					"cw.SK_pbSekindo_84373598ad9c0ca410_firePix('https://live.sekindo.com/live/liveView.php?PBTRK=1&PBSESSID=pbSekindo_84373598ad9c0ca410&adType=tag&subId=simpleprogrammer.com&reqSpace2AdId=0&ecpmValue=0&sspDescripancySpace2AdId=0&spaceId=84373&isPassBack=0&diaid=&userIpAddr=103.242.99.254&userUA=Mozilla%2F5.0+%28Windows+NT+6.3%3B+Win64%3B+x64%29+AppleWebKit%2F537.36+%28KHTML%2C+like+Gecko%29+Chrome%2F60.0.3112.90+Safari%2F537.36&x=300&y=250&campaignFreqCap=&campaignId=&space2AdId=&frcCst=0');"+
					"cw.SK_pbSekindo_84373598ad9c0ca410_verificationCode();" +
					"break;"+
					"} catch (e) {"+
					" continue;"+
					"}}w = w.parent;}"+
					"</scr"+"ipt>";

				try
				{
					window.pbjs.sekindoCB('30a7a3d837d740b', HB_bid);
				}
				catch(e){}
