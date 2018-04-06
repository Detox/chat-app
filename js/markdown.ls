/**
 * @package Detox chat app
 * @author  Nazar Mokrynskyi <nazar@mokrynskyi.com>
 * @license 0BSD
 */
function Wrapper (marked)
	renderer		= new marked.Renderer()
	renderer.link	= ->
		marked.Renderer::link.apply(@, &).replace(/<a/, '$& target="_blank" rel="noreferrer noopener"')
	# Don't render images, treat them as links
	renderer.image	= renderer.link
	options			=
		baseUrl		: '#'
		breaks		: true
		gfm			: true
		headerIds	: false
		renderer	: renderer
		sanitize	: true
		tables		: true

	(markdown_text) ->
		marked(markdown_text, options)

define(['marked'], Wrapper)
