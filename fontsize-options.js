// author: Mike Gillespie
// Based on official Redactor FontSize Plug-in

if (!RedactorPlugins) var RedactorPlugins = {};

RedactorPlugins.fontsize = {
	init: function()
	{
		var dropdown = {};
		var that = this;
		
		//use the appropriate section for the unit you prefer
		// PT
		var fonts = [{'Small':8},{'Normal':10},{'Large':14},{'X-Large':18},{'Giant':30},];
		var units = 'pt'; // valid values are px, pt, em, %
		
		/*// PX
		var fonts = [{'Small':8},{'Normal':10},{'Large':18},{'X-Large':26},{'Giant':36},];
		var units = 'px'; // valid values are px, pt, em, %*/
		
		/*// EM
		var fonts = [{'Small':.75},{'Normal':1},{'Large':1.3},{'X-Large':2},{'Giant':4},];
		var units = 'em'; // valid values are px, pt, em, %*/
		
		/*// %
		var fonts = [{'Small':80},{'Normal':100},{'Large':140},{'X-Large':180},{'Giant':300},];
		var units = '%'; // valid values are px, pt, em, %*/
		
		// create the dropdown
		$.each(fonts, function(i, o){
			$.each(o,function(k,v){
				dropdown['s' + i] = { title: v + units +' ('+k+')', callback: function() { that.setFontsize(v,units); } };
			});			
		});

		dropdown['remove'] = { title: 'Remove font size', callback: function() { that.resetFontsize(); } };

		this.buttonAdd('fontsize', 'Change font size', false, dropdown);
	},
	setFontsize: function(size,units)
	{
		this.inlineSetStyle('font-size', size + units);
	},
	resetFontsize: function()
	{
		this.inlineRemoveStyle('font-size');
	}
};
