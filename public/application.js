$(document).ready(function()  {

    $(document).on("click", "#hit_button", function(){
    // alert("Player Hits");
    $.ajax({
      type: "POST",
      url:"/hit_stay",
      data: {hit_stay: "hit"}
    }).done(function(msg){
        // alert(msg);
        $("#game").replaceWith(msg)
    });


    return false;
  });

  $("#stay_button").click(function() {
    $.ajax({
      type: "POST",
      url:"/hit_stay",
      data: {hit_stay: "stay"}
    }).done(function(msg){
        // alert(msg);
        $("#game").replaceWith(msg)
    });


    return false;
  });
});