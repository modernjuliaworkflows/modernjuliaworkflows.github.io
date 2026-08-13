+++
title = "Fixture page"
+++

Intro text with \tldr{a Franklin command left untouched}.

## Julia mode


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> x = 21
21

<span class="sgr32"><span class="sgr1">julia&gt;</span></span> 2x
42
</pre>
{% endraw %}

State and `ans` persist across named fences:


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> ans - x
21
</pre>
{% endraw %}


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> function double(n)
    return 2n
end;

<span class="sgr32"><span class="sgr1">julia&gt;</span></span> double(4)
8

<span class="sgr32"><span class="sgr1">julia&gt;</span></span> println(&quot;printed, not returned&quot;)
printed, not returned
</pre>
{% endraw %}


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> collect(1:8)
8-element Vector{Int64}:
 1
 2
 3
 4
 5
 6
 7
 8
</pre>
{% endraw %}

Errors render REPL-style instead of failing the build:


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> sqrt(-1)
<span class="sgr91"><span class="sgr1">ERROR: </span></span>DomainError with -1.0:
sqrt was called with a negative real argument but will only return a complex result if called with a complex argument. Try sqrt(Complex(x)).
</pre>
{% endraw %}

The next fence has no blank line above it:

{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> 1 + 1
2
</pre>
{% endraw %}

## Logging


```julia
function warn_func(n)
    @warn "This is bad" n
end
```


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> warn_func(3)
<span class="sgr33"><span class="sgr1">┌ Warning: </span></span>This is bad
<span class="sgr33"><span class="sgr1">│ </span></span>  n = 3
<span class="sgr33"><span class="sgr1">└ </span></span><span class="sgr90">@ Main.MJW_page_index warn-func:2</span>
</pre>
{% endraw %}

## Help mode



{% raw %}
<pre class="julia-repl ansi"><span class="sgr33"><span class="sgr1">help?&gt;</span></span> greet
<span class="sgr36">  greet(name)</span>

  Print a greeting to <span class="sgr36">name</span>.
</pre>
{% endraw %}

## Package mode


{% raw %}
<pre class="julia-repl ansi"><span class="sgr34"><span class="sgr1">(page) pkg&gt;</span></span> status
<span class="sgr32"><span class="sgr1">Status</span></span> `<TMPDIR>/src/page/Project.toml` (empty project)
</pre>
{% endraw %}

## Shell mode


{% raw %}
<pre class="julia-repl ansi"><span class="sgr31"><span class="sgr1">shell&gt;</span></span> echo hello from the shell
hello from the shell

<span class="sgr31"><span class="sgr1">shell&gt;</span></span> printf &#39;two\nlines\n&#39;
two
lines
</pre>
{% endraw %}

Shell and julia fences share the page's scratch working directory:


{% raw %}
<pre class="julia-repl ansi"><span class="sgr31"><span class="sgr1">shell&gt;</span></span> echo scratch &gt; created.txt
</pre>
{% endraw %}


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> read(&quot;created.txt&quot;, String)
&quot;scratch\n&quot;
</pre>
{% endraw %}

## Plain fences


```julia
println("plain fence output")
```

{% raw %}
<pre class="code-output ansi">plain fence output
</pre>
{% endraw %}


```julia
visible_line = hidden_setup + 1;
```


## Static REPL blocks


{% raw %}
<pre class="julia-repl ansi"><span class="sgr32"><span class="sgr1">julia&gt;</span></span> 1 + 1
2

<span class="sgr34"><span class="sgr1">(demo) pkg&gt;</span></span> st
</pre>
{% endraw %}

## Passthrough

```julia
unexecuted() = "not run"
```

````markdown
A fence inside a fence:

```julia
inner() = 1
```
````

```bash
echo untouched
```

Legacy Franklin directives are dropped with a warning:



The end.
