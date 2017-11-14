SpreeScaffold
=============

An advanced admin scaffold generator for Spree
Creates a CRUD interface for whatever you want to use the Spree admin styling

Support following functions:
1.  Attachments
2.  Search
3   Sorting
4.  locales
5.  Ready to print pdf
6.  Json api
7.  Foreign key data selection 
8.  Translations
9.  Basic validation
10. Sample data seeding

Installation
============

Add this line to your application's Gemfile:
```ruby
group :development do
  gem 'spree_scaffold', github: 'wuboy0307/spree_scaffold', branch: 'X-X-stable'
end
```

And then execute:

    $ bundle

Usage
=====

Generate a scaffold for the new `Task` model:

    $  rails g spree_scaffold:scaffold class_name name:string slug:string user_id:integer
                                      description:text image:image order_id:integer
                                      important:boolean task_date:datetime
                                      [--search=name user_id important]
                                      [--locale=zh-TW:任務]
                                      [--fk=order:order_id user:user_id]
                                      [--presence name]
                                      [--unique name]

And adjust the [glyphicons](http://glyphicons.com/) icon name on the `app/overrides/spree/admin/add_spree_...` file.

It's better if the first attribute is the "main" text one (name, title etc.)

Some more magic:
* The admin index list will be sortable with drag&drop if you create a `position:integer` field
* `paperclip` image and file attachments are supported: e.g. `picture:image attachment:file`
* Will use `friendly_id` for slugs if a `slug:string` field is present

Example output:

	    app/models/class_name.rb
	    app/controllers/admin/class_names_controller.rb
	    app/views/admin/class_names/index.html.erb
	    app/views/admin/class_names/new.html.erb
	    app/views/admin/class_names/edit.html.erb
	    app/views/admin/class_names/_form.html.erb
	    app/views/admin/class_names/show.html.erb
	    app/views/admin/class_names/index.pdf.erb
	    app/views/admin/class_names/batch.pdf.erb
	    app/views/admin/class_names/show.pdf.erb
	    app/views/admin/class_names/_object.pdf.erb
	    app/views/api/vi/class_names/index.v1.rabl
	    app/views/api/vi/class_names/show.v1.rabl
	    db/migrate/TIMESTAMP_create_class_names.rb
        db/samples/class_names.rb
        lib/class_names/class_name.rake
	    config/locales/class_names.en.yml
	    config/locales/class_names.zh-TW.yml
	    config/locales/spree_scaffold.en.yml
	    config/locales/spree_scaffold.zh-TW.yml

Then run the migration:

    $ rake db:migrate

To rollback:

    $ rake db:rollback
    $ rails destroy spree_scaffold:scaffold Brand name:string description:text position:integer ...

Copyright (c) 2015 Ernest Wu, released under the New BSD License
