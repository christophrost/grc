/*
 *= require application
 *= require jquery
 *= require jquery-ui
 *= require bootstrap
 *= require spin.min
 *= require_self
 */

// Expand node content when '+' clicked in tree
jQuery(function($) {
  $('ul.slugtree .expander').bind('click', function(e) {
    $(this).closest('li').find('> .content').toggle();
  });
});

// Tabs via AJAX on 'Quick Find'
jQuery(function($) {
  $('.tabbable').on('show', 'ul.nav-tabs > li > a', function(e, href) {
    var $tab = $(e.target)
      , loaded = $tab.data('tab-loaded')
      , pane = ($tab.data('tab-target') || $tab.attr('href'))
      , template = "<div></div>";

    if (href)
      loaded = false;
    else
      href = $tab.data('tab-href');

    if (!href) return;

    if (!loaded) {
      if (template) {
        var spinner = new Spinner({ }).spin();
        $(pane).append(spinner.el);
        $(spinner.el).css({ width: '100px', height: '100px', left: '50px', top: '50px' });
      }

      $(pane).load(href, function(data, status, xhr) {
        $tab.data('tab-loaded', true);
        $tab.tab('show');
        $(this).html(data);
      });
    }
  });

  // Trigger first tab immediately
  $('.tabbable > ul > li:first-child > a').tab('show');
});

// Quick Search
jQuery(function($) {
  $('nav > .widgetsearch').keypress(function (e) {
    var $tab = $(this).closest('.WidgetBox').find('ul.nav-tabs > li.active > a')
      , href = $tab.data('tab-href') + '?' + $.param({ s: $(this).val() });
    if (e.which == 13)
      $tab.trigger('show', href);
  });
  $('.nav-box > .widgetsearch').keypress(function (e) {
    if (e.which == 13) {
      var $this = $(this);
      var $box = $($this.closest('.WidgetBox').find('.WidgetBoxContent').children()[0])
        , href = $box.data('href') + '?' + $.param({ s: $(this).val() });
      $box.load(href);
    }
  });
});
