package sitegen

import "core:fmt"
import "core:os"
import "core:strings"

content_directory :: "../content"
generated_directory :: "../generated"
main_style :: "/assets/main.css"

main :: proc() {
	generate_directory(content_directory, generated_directory)
}

generate_html_file_from_md_file :: proc(input_path: string, output_path: string) {
	data, error := os.read_entire_file(input_path, context.allocator)
	if error != nil {
		fmt.println(error)
		return
	}

	builder := strings.builder_make()
	strings.write_string(&builder, "<!DOCTYPE html>\n")
	strings.write_string(&builder, "<html>\n")
	strings.write_string(&builder, "\t<head>\n")
	strings.write_string(&builder, "\t\t<link rel=\"stylesheet\" href=\"/assets/main.css\">\n")
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
	strings.write_string(&builder, "\t\t<script src=\"/assets/include-katex.js\"></script>\n")
	strings.write_string(&builder, "\t</head>\n")
	strings.write_string(&builder, "\t<body>\n")

	strings.write_string(&builder, markdown_to_html(string(data)))

	strings.write_string(&builder, "\t</body>\n")
	strings.write_string(&builder, "</html>\n")

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
