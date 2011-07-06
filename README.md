# email-chef

EmailChef takes HTML and CSS and compiles them into inline `.html` files

## installation

    $ git clone git://github.com/donutcode/email-chef.git
    $ npm install -g email-chef

## update

    $ cd email-chef
    $ git pull origin master
    $ npm install -g .
    
## usage

Compile a file

    $ chef sample.html

Compile all `.html` files in a directory

    $ chef path/to/email_templates/
    
Watch a file/directory and continuously compile when it changes

    $ chef -w my_templates/
    
For additional help

    $ chef --help
    
&copy;2011 donutcode. See `LICENSE` for more information
