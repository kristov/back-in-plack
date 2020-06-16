# Plack is all you need (almost)

I have this thing at the moment where I dislike frameworks. It's about the inversion of control of a tool vs a framework. You use a tool from inside your code, where you control when and how the tool is used. A framework wraps your code, and the framework decides when your code is called. I have a belief that frameworks allow you to get code up and running fast, but in the long term slow development as your application gradually deviates from the world-view imposed by the framework. I want to convince you that if you are writing a web application in Perl (if for some strange reason you want that) you do not want or need any framework nonsense.

Lets start with how you are going to bootstrap your application:

    curl -L http://cpanmin.us | sudo perl - App::cpanminus
    sudo cpanm Carton

These two little ditties give you an easy way to manage and bundle dependencies for your application. If you don't like piping things from the internet into `sudo` the good news is you are *sane*. You are totally free to download it first, check the checksum, read the source code etc - or perhaps just install it some other way that you trust (`sudo apt-get install cpanminus`). Next up let's create the application:

    mkdir my-cool-app
    cd my-cool-app
    plackup app.psgi

And you should see this:

    bash: plackup: command not found

Great that's what we want, so now do this:

    echo "requires 'Plack';" >> cpanfile
    carton install

This will install all the dependencies needed to run a Plack application in the `local/` directory in your new app directory. You should get something like:

    Installing modules using my-cool-app/cpanfile
    Successfully installed File-ShareDir-Install-0.13
    Successfully installed Test-SharedFork-0.35
    ...

It would be good if that didn't install 20Mb of crap. But hey, it's 2020. Once that's done run this:

    perl -Ilocal/lib/perl5 local/bin/plackup app.psgi

And you should see what we expect:

    Error while loading app.psgi: No such file or directory at (eval 8) line 4.

Great, we haven't created that file yet so we are all good. Let's create the file and put this in it:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    my $app = sub {
        my ($env) = @_;
        return "Hello";
    };
    $app;

Now when you run it using the `plackup` command above you should see a something like this:

    HTTP::Server::PSGI: Accepting connections at http://0:5000/

Awesome! A web application! Well, not quite... If you hit `http://localhost:5000/` you will get an error:

    Response should be array ref or code ref: Hello at local/lib/perl5/Plack/Middleware/Lint.pm line 104

You need to return an arrayref from your plack application:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    my $app = sub {
        my ($env) = @_;
        return [
            200,
            [],
            ["Hello"],
        ];
    };
    $app;

An that is it. You can see that 200 is the response code, the second arrayref are headers you want to return, and you can go nuts replacing "Hello" with any damn HTML you please. You can even generate that HTML in *any way you like*! Imagine the freedom to do whatever you want!! Look at all the nonsense that *isn't* there. Every time your browser makes a request that sub is invoked with no nonsense whatsoever. So clean, so simple.

Unfortunately `use strict; use warnings;` is a bit of Perl nonsense that we must do. I tried to find out if it were possible to compile Perl with strict and warnings always turned on but didn't get far. You can achieve the same thing like so:

    perl -Mstrict -Mwarnings -Ilocal/lib/perl5 local/bin/plackup app.psgi

You could even make an alias:

    alias perlstrict="perl -Mstrict -Mwarnings"

Or like whatever you want.

# Adding some nonsense

Now I have shown you the (relatively) pure path, I feel obliged to add some nonsense. The good news is that the following nonsense is *completely optional* for you. Take it or leave it! The first is an object that we will create from the `$env` variable, since `$env` is a little bit unwieldy:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Plack::Request;
    my $app = sub {
        my ($env) = @_;
        my $request = Plack::Request->new($env);
        return [
            200,
            [],
            ["<h1>Hello " . $request->path . "</h1>"],
        ];
    };
    $app;

Huh. Well, it gives you a convenient way to get at request parameters. The second bit of nonsense is a convenience wrapper around that array ref:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Plack::Request;
    use Plack::Response;
    my $app = sub {
        my ($env) = @_;
        my $request = Plack::Request->new($env);
        my $response = Plack::Response->new;
        $response->status(200);
        $response->body("<h1>Hello " . $request->path . "</h1>");
        return $response->finalize;
    };
    $app;

The `Plack::Response` has some some interesting things there, like setting headers and doing redirects.

OK, one more bit of nonsense for you:

    echo "requires 'Template';" >> cpanfile
    carton install

And make a bit of changes to your thing:

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Plack::Request;
    use Plack::Response;
    use Template;
    my $tt = Template->new({INCLUDE_PATH => "./"});
    my $app = sub {
        my ($env) = @_;
        my $request = Plack::Request->new($env);
        my $response = Plack::Response->new;
        $response->status(200);
        my $body = "";
        $tt->process("hello.html", {path => $request->path}, \$body);
        $response->body($body);
        return $response->finalize;
    };
    $app;

And in `hello.html`:

    <h1>Hello [% path %]</h1>

Wowee, you just separated your application and presentation logic like a boss. 

## The End

That is literally and figuratively the end. Like WTF else do you need? Go bananas adding whatever crap you want after that. Add application builders, factories, design patterns, callback hooks, dispatch logic, MVC, MVP, MVVM... Just know that all that crap and nonsense is on *you* - you did that and no one else!
