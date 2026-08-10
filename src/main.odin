package sitegen

import "core:fmt"
import "core:os"
import "core:strings"

content_directory :: "../content"
generated_directory :: "../generated"
main_style :: "/assets/css/main.css"

main :: proc() {
	generate_directory(content_directory, generated_directory)
}

generate_html_file_from_md_file :: proc(input_path: string, output_path: string) {
	current_directory: string = input_path
	fmt.println(current_directory)

	data, error := os.read_entire_file(input_path, context.allocator)
	if error != nil {
		fmt.println(error)
		return
	}

	builder := strings.builder_make()
	strings.write_string(&builder, "<!DOCTYPE html>\n")
	strings.write_string(&builder, "<html>\n")
	strings.write_string(&builder, "\t<head>\n")

	front_matter, markup := parse_front_matter(string(data))

	// title
	strings.write_string(&builder, fmt.aprintf("\t\t<title>%s</title>\n", front_matter.title))

	// main style
	strings.write_string(
		&builder,
		fmt.aprintf("\t\t<link rel=\"stylesheet\" href=\"%s\">\n", main_style),
	)

	// layout
	switch front_matter.layout {
	case "chapter":
		strings.write_string(
			&builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/chapter.css\">\n",
		)
	case "section":
		strings.write_string(
			&builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/section.css\">\n",
		)
		strings.write_string(&builder, "\t\t<link rel=\"stylesheet\" href=\"/assets/math.css\">\n")
	}

	//libraries
	for lib in front_matter.libs {

		// include katex
		if lib == "katex" {
			strings.write_string(
				&builder,
				"\t\t<link rel=\"stylesheet\" href=\"/assets/katex/katex.min.css\">\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script defer src=\"/assets/katex/katex.min.js\"></script>\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script defer src=\"/assets/katex/contrib/auto-render.min.js\"></script>\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script src=\"/assets/include-katex.js\"></script>\n",
			)
		}
	}

	strings.write_string(&builder, "\t</head>\n")
	strings.write_string(&builder, "\t<body>\n")

	// automatic h1
	strings.write_string(&builder, fmt.aprintf("\t\t<h1>%s</h1>\n", front_matter.title))

	// automatic body for index.md linking to subdirectories
	if strings.has_suffix(input_path, "index.md") {
		current_directory = strings.trim_suffix(input_path, "index.md")
		fmt.println(current_directory)

		error: os.Error

		folder: ^os.File
		folder, error = os.open(current_directory)
		if error != nil {
			fmt.println(error)
			return
		}

		items: []os.File_Info
		items, error = os.read_dir(folder, 0, context.allocator)
		if error != nil {
			return
		}

		for item in items {
			if item.type != os.File_Type.Directory {
				continue
			}

			current_directory = fmt.aprintf("%s%s/", current_directory, item.name)
			fmt.println(current_directory)

			// directories become h2
			h2: string = item.name
			strings.write_string(&builder, fmt.aprintf("\t\t<h2>%s</h2>\n", title_from_kebab(h2)))

			// subdirectories become ul->li
			folder, error = os.open(current_directory)
			if error != nil {
				fmt.println(error)
				return
			}

			items: []os.File_Info
			items, error = os.read_dir(folder, 0, context.allocator)
			if error != nil {
				return
			}

			building_list: bool = false
			for item in items {
				if item.type != os.File_Type.Directory {
					continue
				}

				current_directory = fmt.aprintf("%s%s/", current_directory, item.name)
				fmt.println(current_directory)

				if !building_list {
					strings.write_string(&builder, "\t\t<ul>\n")
					building_list = true
				}

				if building_list {
					link := fmt.aprintf(
						"%s%s%s",
						"../generated/",
						strings.trim_prefix(current_directory, "../content/"),
						"index.html",
					)

					strings.write_string(
						&builder,
						fmt.aprintf(
							"\t\t\t<li><a href=\"%s\">%s</a></li>\n",
							link,
							title_from_kebab(item.name),
						),
					)
				}

				current_directory = strings.trim_suffix(
					current_directory,
					fmt.aprintf("%s/", item.name),
				)
				fmt.println(current_directory)
			}

			if building_list {
				strings.write_string(&builder, "\t\t</ul>\n")
			}

			current_directory = strings.trim_suffix(
				current_directory,
				fmt.aprintf("%s/", item.name),
			)
			fmt.println(current_directory)
		}
	}

	// manual body
	strings.write_string(&builder, markdown_to_html(markup))
	strings.write_string(&builder, "\t</body>\n")
	strings.write_string(&builder, "</html>\n")

	// generate .html file
	output := strings.to_string(builder)
	error = os.write_entire_file_from_string(output_path, output)
	if error != nil {
		fmt.println(error)
		return
	}
}

generate_directory :: proc(content_path: string, generated_path: string) {
	error: os.Error
	folder: ^os.File
	folder, error = os.open(content_path)
	if error != nil {
		fmt.println(error)
		return
	}

	items: []os.File_Info
	items, error = os.read_dir(folder, 0, context.allocator)
	if error != nil {
		return
	}

	for item in items {
		if item.type == os.File_Type.Directory {
			content_directory_path := fmt.aprintf("%s/%s", content_path, item.name)

			// check for missing index.md in content directory
			found_index: bool = false
			folder, error = os.open(content_path)
			if error != nil {
				fmt.println(error)
				return
			}

			items: []os.File_Info
			items, error = os.read_dir(folder, 0, context.allocator)
			if error != nil {
				return
			}

			for item in items {
				if strings.has_suffix(item.name, "index.md") {
					found_index = true
				}
			}
			if !found_index {

				// generate index.md
				front_matter_text := fmt.aprintf(
					"---\ntitle: %s\n---\n",
					title_from_kebab(item.name),
				)

				error = os.write_entire_file_from_string(
					fmt.aprintf("%s%s", item.fullpath, "/index.md"),
					front_matter_text,
				)
				if error != nil {
					fmt.println(error)
					return
				}
			}

			generated_directory_path := fmt.aprintf("%s/%s", generated_path, item.name)
			os.make_directory(generated_directory_path)
			generate_directory(content_directory_path, generated_directory_path)
		} else {
			content_file_path := fmt.aprintf("%s/%s", content_path, item.name)
			generated_file_path := fmt.aprintf(
				"%s/%s.html",
				generated_path,
				strings.trim_suffix(item.name, ".md"),
			)
			generate_html_file_from_md_file(content_file_path, generated_file_path)
		}
	}

	os.close(folder)
}

title_from_kebab :: proc(input: string) -> string {
	parts := strings.split(input, "-")
	builder := strings.builder_make()
	for part, i in parts {
		if i > 0 {
			strings.write_string(&builder, " ")
		}
		c := part[0]
		if 'a' <= c && c <= 'z' {
			c = c - 'a' + 'A'
		}
		strings.write_string(&builder, fmt.aprintf("%c%s", c, part[1:]))
	}
	return strings.to_string(builder)
}
