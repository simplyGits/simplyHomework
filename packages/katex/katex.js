/* global katex */

if (Package.templating) {
	const Template = Package.templating.Template;
	const Blaze = Package.blaze.Blaze; // implied by `templating`
	const HTML = Package.htmljs.HTML; // implied by `blaze`

	Template.registerHelper('katex', new Template('katex', function () {
		let content = '';
		if (this.templateContentBlock) {
			content = Blaze._toText(this.templateContentBlock, HTML.TEXTMODE.STRING);
		}

		try {
			return HTML.Raw(
				content.replace(/\$\$(.+)\$\$/, function (match, formula) {
					return katex.renderToString(formula);
				})
			);
		} catch (error) {
			return this.templateElseBlock || HTML.Raw(content);
		}
	}));
}
