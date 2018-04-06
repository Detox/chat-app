// Generated by LiveScript 1.5.0
/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
(function(){
  function Wrapper(marked){
    var renderer, options;
    renderer = new marked.Renderer();
    renderer.link = function(){
      return marked.Renderer.prototype.link.apply(this, arguments).replace(/<a/, '$& target="_blank" rel="noopener"');
    };
    renderer.image = renderer.link;
    options = {
      baseUrl: '#',
      breaks: true,
      gfm: true,
      headerIds: false,
      renderer: renderer,
      sanitize: true,
      tables: true
    };
    return function(markdown_text){
      return marked(markdown_text, options);
    };
  }
  define(['marked'], Wrapper);
}).call(this);
