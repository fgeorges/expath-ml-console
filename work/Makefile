NAME=expath-ml-console-0.5.0dev

../dist/$(NAME).zip:
	mkdir $(NAME)
	cp README $(NAME)/
	cp -r ../src/ $(NAME)/src
	rm -f $@
	zip -r $@ $(NAME)/
	rm -rf $(NAME)

.PHONY: ../dist/$(NAME).zip
