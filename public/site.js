$(function() {
  $('#wrap').click(function() {
    $(this).button('toggle');
    if ($(this).hasClass('active')) {
      $('#paste').addClass('wrap');
    } else {
      $('#paste').removeClass('wrap');
    }
  });

  $('#paste').each(function(i, block) {
    hljs.highlightBlock(block);
  });
});
