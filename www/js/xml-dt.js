
var xml$dt = {};

xml$dt.process = function(str, conf) {
    var parser = new DOMParser();
    var xml = parser.parseFromString(str, "text/xml");

    if (!('#document' in conf)) {
	conf['#document'] = function(q,c,v) { return c; };
    }

    if ('#map' in conf) {
        var keys = Object.keys(conf['#map']);
        for (var i = 0; i < keys.length; i++) {
            /* Yep, this is a closure! */
            (function() {
            var outTag = conf['#map'][keys[i]];
            conf[keys[i]] = function(q,c,v){return xml$dt.tag( outTag, c,v);};
            })();
        }
    }
    
    return xml$dt.__dt(xml, conf);
};

xml$dt.tag = function(name, content, attr) {
    attr = attr || {};
    
    var r = "<" + name;
    
    var keys = Object.keys(attr);
    keys.sort();
    for (var i = 0; i < keys.length; i++) {
	    r += " " + keys[i] + "=\"" + attr[keys[i]] + "\"";
    }
    
    if (content) {
    	r += ">" + content + "</" + name + ">";
    }
    else {
	    r += "/>";
    }
    return r;
};


xml$dt.__map = function (list, func) {
    var r = [];
    for (var i = 0; i < list.length; i++) {
	    r.push(func(list[i]));
    }
    return r;
};

xml$dt.__dt = function (element, conf) {
    var child;
    if (element.childNodes.length > 0) {
        childs = xml$dt.__map(element.childNodes, function(x) { 
            return xml$dt.__dt(x, conf); 
        });
        child = childs.join("");
    }
    else {
	    child = element.data;
    }
    
    var attr = {};
    var attributes = element.attributes; // nodeName / nodeValue
    for (var i = 0; attributes && i < attributes.length; i++) {
	    attr[attributes[i].nodeName] = attributes[i].nodeValue;
    }
    
    var result = child;
    if (element.nodeName in conf) {
	    result = conf[element.nodeName](element.nodeName, child, attr);
    }
    else if ("#default" in conf && element.nodeName != "#text") {
	    result = conf["#default"](element.nodeName, child, attr);	
    }
    
    return result;
};

