package sitegen

import "core:fmt"
import "core:strings"

parse_front_matter :: proc(input: string) -> (front_matter: Front_Matter, markdown: string) {
	front_matter = Front_Matter{}
	markdown = input

	if !strings.has_prefix(input, "---") {
		return
	}

	// separate front matter and markup
	front_matter_text_start := strings.index(input, "---") + 3
	front_matter_text_end :=
		front_matter_text_start + strings.index(input[front_matter_text_start:], "---")
	front_matter_text := input[front_matter_text_start:front_matter_text_end]
	markdown = input[front_matter_text_end + 3:]

	reading_libs: bool = false
	reading_katex_macros: bool = false
	for line in strings.split_lines(front_matter_text) {

		// title
		if strings.has_prefix(line, "title: ") {
			front_matter.title = line[7:]
			continue
		}

		// description
		if strings.has_prefix(line, "description: ") {
			front_matter.description = line[13:]
			continue
		}

		// video
		if strings.has_prefix(line, "video: ") {
			front_matter.video = line[7:]
			continue
		}

		// layout
		if strings.has_prefix(line, "layout: ") {
			layout_string := line[8:]
			switch layout_string {
			case "chapter":
				front_matter.layout = Layout.Chapter
			case "section":
				front_matter.layout = Layout.Section
			}
			continue
		}

		// chapter and section
		if strings.has_prefix(line, "chapter: ") {
			continue
		}
		if strings.has_prefix(line, "section: ") {
			continue
		}

		// libraries
		if strings.has_prefix(line, "libs:") {
			reading_libs = true
			continue
		}
		if reading_libs {
			if strings.has_prefix(line, "    ") {
				lib_string := line[4:]
				switch lib_string {
				case "katex":
					append(&front_matter.libs, Lib.KaTeX)
				}
				continue
			}
			reading_libs = false
		}

		// katex macros
		if strings.has_prefix(line, "katex_macros:") {
			debug("Found KaTeX macros!")
			reading_katex_macros = true
			front_matter.katex_macros = make(map[string]string)
			continue
		}
		if reading_katex_macros {
			if strings.has_prefix(line, "    ") {
				parts := strings.split(line[4:], ":")
				macro := strings.trim(parts[0], "\"")
				definition := strings.trim(parts[1], "\"")
				debug("macro:", macro, "\ndefinition:", definition)
				front_matter.katex_macros[macro] = definition
				continue
			}
			reading_katex_macros = false
		}
	}

	return front_matter, markdown
}

markdown_to_html :: proc(input: string) -> string {
	builder := strings.builder_make()
	building_paragraph: bool = false
	building_list: bool = false

	for line in strings.split_lines(input) {

		// heading 1
		if strings.has_prefix(line, "# ") {
			strings.write_string(&builder, fmt.aprintf("\t\t<h1>%s</h1>\n", line[2:]))
			continue
		}

		// heading 2
		if strings.has_prefix(line, "## ") {
			strings.write_string(&builder, fmt.aprintf("\t\t<h2>%s</h2>\n", line[3:]))
			continue
		}

		// unordered list
		if strings.has_prefix(line, "- ") {
			if !building_list {
				strings.write_string(&builder, "\t\t<ul>\n")
				building_list = true
			}

			list_item := line[2:]

			// link in unordered list
			if strings.has_prefix(list_item, "[") {
				strings.write_string(&builder, "\t\t\t<li>")
				strings.write_string(&builder, markdown_parse_link(list_item))
				strings.write_string(&builder, "</li>\n")

				// regular list item
			} else {
				strings.write_string(&builder, fmt.aprintf("\t\t\t<li>%s</li>\n", list_item))
			}
			continue
		} else {
			if building_list {
				strings.write_string(&builder, "\t\t</ul>\n")
				building_list = false
			}
		}

		// link
		if strings.has_prefix(line, "[") {
			strings.write_string(&builder, markdown_parse_link(line))
			continue
		}

		// paragraphs
		if line != "" {

			// start paragraph
			if !building_paragraph {
				building_paragraph = true
				strings.write_string(&builder, "\t\t<p>\n\t\t\t")
			}

			// parse line
			for i := 0; i < len(line); i += 1 {
				if line[i] == '\\' {

					// skip '\'
					i += 1

					// TODO: think about [] being used within a command...
					// display math
					if line[i] == '[' {
						strings.write_string(&builder, fmt.aprintf("<div class=\"display\">$"))

						i += 1 // skip '['

						// parse display math line
						text: string = ""
						for i < len(line) {

							// end at '\]'
							if line[i] == '\\' {
								if line[i + 1] == ']' {
									break
								}
							}

							// write , and . as text
							if line[i] == ',' || line[i] == '.' {
								strings.write_string(&builder, "\\text{")
								strings.write_byte(&builder, line[i])
								strings.write_string(&builder, " }")
								i += 1
								continue
							}

							strings.write_byte(&builder, line[i])
							i += 1
						}
						//text = line[display_start:i - 1]

						strings.write_string(&builder, fmt.aprintf("$</div>"))

						break
					}

					// commands
					accum: int = 1 // to reverse advancing i

					// TODO: think about {} being used within a command...
					command_start := i
					for i < len(line) && line[i] != '{' {
						i += 1
						accum += 1
					}
					command := line[command_start:i]

					switch command {

					// defn
					case "defn":
						argument_start := i + 1 // skip '{'
						i += 1
						accum += 1
						for i < len(line) && line[i] != '}' {
							i += 1
							accum += 1
						}
						argument := line[argument_start:i]
						strings.write_string(
							&builder,
							fmt.aprintf("<span class=\"definition\">%s</span>", argument),
						)
						i += 1 // skip '}'
						accum += 1
					case:
						i -= accum
					}
				}

				strings.write_byte(&builder, line[i])
			}
		} else if line == "" {
			if building_paragraph {
				strings.write_string(&builder, "\n\t\t</p>\n")
				building_paragraph = false
			}
		}
	}

	// done with file, so close any opened elements
	if building_list {
		strings.write_string(&builder, "\t\t</ul>\n")
	}

	if building_paragraph {
		strings.write_string(&builder, "\n\t\t</p>\n")
	}

	return strings.to_string(builder)
}

markdown_parse_link :: proc(link: string) -> (html: string) {
	closing_bracket: int = strings.index(link, "]")
	closing_paren: int = strings.index(link, ")")
	url := link[closing_bracket + 2:closing_paren]
	text := link[1:closing_bracket]
	return fmt.aprintf("<a href=\"%s\">%s</a>", url, text)
}
