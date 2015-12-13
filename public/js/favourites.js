
$(
    function() {
        $("#revision").change(
            function() {
                $("#revision").submit();
            }
        );
    }
)

function favourite(element, action, wordid ) {
    $.ajax( {
        url: "/ajax/favourites",
        dataType: 'json',
        cache: false,
        context: element,
        data: {
            wid: wordid,
            task: action,
        },
        success: function(data) {
            if (data.error) {
                alert(data.error);
            } else {
                if (this.src.match(/delete/)) {
                    this.src = '/images/heart_add.png';
                    this.onclick = function(){favourite(this, 'add', wordid);};
                } else {
                    this.src = '/images/heart_delete.png';
                    this.onclick = function(){favourite(this, 'remove', wordid);};
                }
                this.alt = data.ok;
                this.title = data.ok;
            }
        },
        error: function(request, status, erro) {
            alert("Neste momento não é possível satisfazer o seu pedido.");
        }
    });
}

