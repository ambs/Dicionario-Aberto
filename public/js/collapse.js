


function collapse() {
    document.getElementById('header').style.width = "900px";
    document.getElementById('header').style.height = "90px";
    document.getElementById('header').style.position = "relative";
    
    document.getElementById('logo').style.cssFloat = "left";
    document.getElementById('search').style.cssFloat = "right";
    document.getElementById('search').style.position = "absolute";
    document.getElementById('search').style.bottom = "0px";
    document.getElementById('search').style.right = "0px";

    document.getElementById('seta').style.clear = "both";
    document.getElementById('setaimg').onclick = function() { return expand(); };
    document.getElementById('setaimg').src = "/images/down.png";

    document.getElementById('range').style.textAlign = "left";

    $.cookie('collapsed', 'yes', { path: "/", expires: 365 });
}

function expand() {
    document.getElementById('setaimg').src = "/images/up.png";
    document.getElementById('header').style.width = "46.46em";
    document.getElementById('header').style.height = "auto";
    document.getElementById('search').style.cssFloat = "none";
    document.getElementById('logo').style.cssFloat = "none";
    document.getElementById('search').style.position = "relative";
    document.getElementById('setaimg').onclick = function() { return collapse(); };

    document.getElementById('range').style.textAlign = "center";

    $.cookie("collapsed", "no", {expires: 365, path: "/"});
}
