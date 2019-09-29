# ProgressPuppy - FOSS Edition

ProgressPuppy - FOSS Edition is a web-based productivity app whose main purpose is to manage your daily tasks. It's written in Ruby on Rails, and this codebase is derived from what's currently running at https://progresspuppy.com.

Using ProgressPuppy is intended to add some fun to completing your daily tasks. Upon task completion, a funny or motivating internet meme is displayed.

Not included in the FOSS Edition of the codebase are paid subscription plan definitions, payment processor code, predefined productivity quote packs, and production tooling that require site-specific setup such as exception notifications, email server settings, or app deployment.

See the Adding Memes section below for instructions on how to configure your own custom memes - this codebase only comes with three memes configured.

## Setup Notes

This app is based on the Ruby on Rails 6.0.0 framework, which requires Ruby 2.5 or later. Review the Gemfile to see what ruby gems are needed.

To set up the sqlite3 default databases, run `rails db:migrate`.

The `db/seeds.rb` file sets up a default user with the login credentials **admin@example.com / foobarbaz123**. That user will get created when you first run the database migrations as described above.

## Adding Memes

You can add your own memes by adding a partial template under `app/views/tasks/`. The partial should have a filename prefixed with "awwyiss_modal". Then add the name of the partial to the array that is returned in the `meme_modal_list()` method in `app/controllers/tasks_controller.rb`.

## Running Tests

A reasonable set of model, integration, and capybara-based system tests are included. You can execute them with `rails test` and `rails test:system`.

## License

ProgressPuppy - FOSS Edition is released under the [GNU Affero General Public License, Version 3](https://www.gnu.org/licenses/agpl-3.0.en.html). See the `LICENSE` file for the full text of this software license.

This software is provided as-is, without any warranties. Use it at your own risk.
