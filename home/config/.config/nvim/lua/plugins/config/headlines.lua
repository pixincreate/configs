return function()
  vim.cmd [[highlight Dash guifg=#D19A66 gui=bold]]

  require("headlines").setup({
    markdown = {
      query = vim.treesitter.query.parse(
        "markdown",
        [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
                (block_quote (paragraph (block_continuation) @quote))
                (block_quote (block_continuation) @quote)
            ]]
      ),
      headline_highlights = { "Headline" },
      bullet_highlights = {
        "@text.title.1.marker.markdown",
        "@text.title.2.marker.markdown",
        "@text.title.3.marker.markdown",
        "@text.title.4.marker.markdown",
        "@text.title.5.marker.markdown",
        "@text.title.6.marker.markdown",
      },
      bullets = { "◉", "○", "✸", "✿" },
      codeblock_highlight = "CodeBlock",
      dash_highlight = "Dash",
      dash_string = "⎯",
      quote_highlight = "Quote",
      quote_string = "┃",
      fat_headlines = true,
      fat_headline_upper_string = "▃",
      fat_headline_lower_string = "🬂",
    },
    rmd = {
      query = vim.treesitter.query.parse(
        "markdown",
        [[
                (atx_heading [
                    (atx_h1_marker)
                    (atx_h2_marker)
                    (atx_h3_marker)
                    (atx_h4_marker)
                    (atx_h5_marker)
                    (atx_h6_marker)
                ] @headline)

                (thematic_break) @dash

                (fenced_code_block) @codeblock

                (block_quote_marker) @quote
                (block_quote (paragraph (inline (block_continuation) @quote)))
                (block_quote (paragraph (block_continuation) @quote))
                (block_quote (block_continuation) @quote)
            ]]
      ),
      treesitter_language = "markdown",
      headline_highlights = { "Headline" },
      bullet_highlights = {
        "@text.title.1.marker.markdown",
        "@text.title.2.marker.markdown",
        "@text.title.3.marker.markdown",
        "@text.title.4.marker.markdown",
        "@text.title.5.marker.markdown",
        "@text.title.6.marker.markdown",
      },
      bullets = { "◉", "○", "✸", "✿" },
      codeblock_highlight = "CodeBlock",
      dash_highlight = "Dash",
      dash_string = "-",
      quote_highlight = "Quote",
      quote_string = "┃",
      fat_headlines = true,
      fat_headline_upper_string = "▃",
      fat_headline_lower_string = "🬂",
    },
  })
end
