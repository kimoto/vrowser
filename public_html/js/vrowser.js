var server_browser = null;
var get_new_data = null;
$(document).ready(function(){
  $.getJSON("/api/connected/json", function(data){
    $("#myTemplate").tmpl(data).appendTo("#servers");

    $("#servers tbody tr").live("dblclick", function(){
      var nTds = $('td', this);
      window.open("steam://connect/" + $(nTds[1]).text());
    });

    $("#servers tbody tr").live("click", function(){
      var nTds = $('td', this);
      console.log("steam://connect/" + $(nTds[1]).text());
    });

    $(window).bind('resize', function(){
      server_browser.fnAdjustColumnSizing(false);
    });

    server_browser = $("#servers").dataTable({
      "bStateSave" : true,
      "bJQueryUI" : true,
      "bPaginate": false,
      "sPaginationType": "full_numbers",
      "bScrollInfinite": true,
      "bScrollCollapse": true,
      "sScrollY": "500px",
      "bAutoWidth": true,
      "bLengthChange": true,
      "oLanguage": {
        "sLengthMenu": "Display _MENU_ records per page",
        "sZeroRecords": "検索条件に一致するサーバーが見つかりませんでした",
        "sInfo": "_TOTAL_件中 _START_ から _END_ 件表示中",
        "sInfoEmpty": "Showing 0 to 0 of 0 records",
        "sInfoFiltered": "(全_MAX_件からフィルタリング)"
      },
      "aoColumnDefs": [
        { "sWidth": "10%", "aTargets": [ -1 ] }
      ]
    })

    get_new_data = function(){
      $.ajax({
        'dataType': 'json',
        'url': '/api/updated/json',
        'cache': true,
        'success': function(data){
          server_browser.fnClearTable(false);
          server_browser.fnAddData(data, false);
          server_browser.fnDraw();
        },
        'error': function(req, stat, thrown){
          //alert(thrown);
        }
      });
    };

    setInterval(function(){
      get_new_data();
    }, 1000 * 30 * 1);
    get_new_data();
  });
});

function update_list(){
  get_new_data();
}
