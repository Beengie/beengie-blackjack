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

  $("#again-yes").click(function() {
    $.ajax({
      type: "POST",
      url:"/place_bet",
      data: {hit_stay: "play"}
    }).done(function(msg){
        // alert(msg);
        $("#game").replaceWith(msg)
    });
    return false;
  });

  $("#quit").click(function() {
    $.ajax({
      type: "POST",
      url:"/place_bet",
      data: {hit_stay: "quit"}
    }).done(function(msg){
        // alert(msg);
        $("#game").replaceWith(msg)
    });
    return false;
  });

  $("#more").click(function() {
    $.ajax({
      type: "POST",
      url:"/more_money",
      data: {hit_stay: "more"}
    }).done(function(msg){
        // alert(msg);
        $("#game").replaceWith(msg)
    });
    return false;
  });
});