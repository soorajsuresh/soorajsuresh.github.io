package sitegen

import "core:fmt"
import "core:strings"

markdown_to_html :: proc(input: string) -> string {
	builder := strings.builder_make()
	building_list: bool = false

	for line in strings.split_lines(input) {

		// heading 1
		if strings.has_prefix(line, "# ") {
			strings.write_string(&builder, fmt.aprintf("<h1>%s</h1>\n", line[2:]))
		}

		// heading 2
		if strings.has_prefix(line, "## ") {
			strings.write_string(&builder, fmt.aprintf("<h2>%s</h2>\n", line[3:]))
		}

		// unordered list
		if strings.has_prefix(line, "- ") {
			if !building_list {
				strings.write_string(&builder, "<ul>\n")
				building_list = true
			}

			// link in unordered list
			link := line[2:]
			if strings.has_prefix(link, "[") {
				strings.write_string(&builder, "\t<li>")
				strings.write_string(&builder, markdown_parse_link(link))
				strings.write_string(&builder, "</li>\n")
			} else {
				strings.write_string(&builder, fmt.aprintf("\t<li>%s</li>\n", line[2:]))
			}
		} else {
			if building_list {
				strings.write_string(&builder, "</ul>\n")
				building_list = false
			}
		}

		// link
		if strings.has_prefix(line, "[") {
			strings.write_string(&builder, markdown_parse_link(line))
		}
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
