$(document).ready(function(){
    $('.proof').addClass("hidden");
        $('.proof > .toggle').click(function() {
            let $this = $(this).parent();
            if ($this.hasClass("hidden")) {
                $(this).parent().removeClass("hidden").addClass("visible");
                $(this).text("Hide Proof");
            } else {
                $(this).parent().removeClass("visible").addClass("hidden");
                $(this).text("Show Proof");
            }
        });
    $('.exercise').addClass("hidden");
    $('.exercise > .toggle').click(function() {
        let $this = $(this).parent();
        if ($this.hasClass("hidden")) {
            $(this).parent().removeClass("hidden").addClass("visible");
            $(this).text("Hide Solution");
        } else {
            $(this).parent().removeClass("visible").addClass("hidden");
            $(this).text("Show Solution");
        }
    });
});