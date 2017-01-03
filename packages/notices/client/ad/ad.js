/* global NoticeManager */

// TODO: how do we know no ad has been loaded (but without an error)?
const adLoaded = new ReactiveVar(false);
let adElement = undefined;

Meteor.startup(function () {
	const data = {
		placementid: '240165609743803_240166086410422',
		format: 'native',
		testmode: false,
		onAdLoaded: function(element) {
			console.log('Audience Network [240165609743803_240166086410422] ad loaded');
			adElement = element;
			adLoaded.set(true);
		},
		onAdError: function(errorCode, errorMessage) {
			console.log('Audience Network [240165609743803_240166086410422] error (' + errorCode + ') ' + errorMessage);
			adLoaded.set(false);
		},
	};

	(function(w, l, d, t) {
		const a = t();
		const b = d.currentScript || (function() {
			const c = d.getElementsByTagName('script');
			return c[c.length - 1];
		})();
		const e = b.parentElement;
		e.dataset.placementid = data.placementid;
		const f = function(v) {
			try {
				return v.document.referrer;
			} catch (e) {
				undefined;
			}
			return '';
		};
		const g = function(h) {
			const i = h.indexOf('/', h.indexOf('://') + 3);
			if (i === -1) {
				return h;
			}
			return h.substring(0, i);
		};
		const j = [l.href];
		let k = false;
		let m = false;
		if (w !== w.parent) {
			let n;
			let o = w;
			while (o !== n) {
				let h;
				try {
					m = m || (o.$sf && o.$sf.ext);
					h = o.location.href;
				} catch (e) {
					k = true;
				}
				j.push(h || f(n));
				n = o;
				o = o.parent;
			}
		}
		const p = l.ancestorOrigins;
		if (p) {
			if (p.length > 0) {
				data.domain = p[p.length - 1];
			} else {
				data.domain = g(j[j.length - 1]);
			}
		}
		data.url = j[j.length - 1];
		data.channel = g(j[0]);
		data.width = screen.width;
		data.height = screen.height;
		data.pixelratio = w.devicePixelRatio;
		data.placementindex = w.ADNW && w.ADNW.Ads ? w.ADNW.Ads.length : 0;
		data.crossdomain = k;
		data.safeframe = !!m;
		const q = {};
		q.iframe = e.firstElementChild;
		let r = 'https://www.facebook.com/audiencenetwork/web/?sdk=5.3';
		for (const s in data) {
			q[s] = data[s];
			if (typeof(data[s]) !== 'function') {
				r += '&' + s + '=' + encodeURIComponent(data[s]);
			}
		}
		q.iframe.src = r;
		q.tagJsInitTime = a;
		q.rootElement = e;
		q.events = [];
		w.addEventListener('message', function(u) {
			if (u.source !== q.iframe.contentWindow) {
				return;
			}
			u.data.receivedTimestamp = t();
			if (this.sdkEventHandler) {
				this.sdkEventHandler(u.data);
			} else {
				this.events.push(u.data);
			}
		}.bind(q), false);
		q.tagJsIframeAppendedTime = t();
		w.ADNW = w.ADNW || {};
		w.ADNW.Ads = w.ADNW.Ads || [];
		w.ADNW.Ads.push(q);
		w.ADNW.init && w.ADNW.init(q);
	})(window, location, document, Date.now || function() {
		return +new Date;
	});

	jQuery.getScript('https://connect.facebook.net/en_US/fbadnw.js');
});

NoticeManager.provide('ad', function() {
	if (!adLoaded.get()) {
		return;
	}

	adElement.style.display = 'block';
	return {
		template: 'ad',
	};
});
