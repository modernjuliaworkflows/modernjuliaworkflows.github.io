+++
title = "Fixture page"
+++

Intro text with \tldr{a Franklin command left untouched}.

## Julia mode

```>state
x = 21
2x
```

State and `ans` persist across named fences:

```>state-2
ans - x
```

```>multiline
function double(n)
    return 2n
end;

double(4)

println("printed, not returned")
```

```>display
collect(1:8)
```

Errors render REPL-style instead of failing the build:

```>error-example
sqrt(-1)
```

The next fence has no blank line above it:
```>tight
1 + 1
```

## Logging

```!warn-func
function warn_func(n)
    @warn "This is bad" n
end
```

```>warn-repl
warn_func(3)
```

## Help mode

```!
# hideall
"""
    greet(name)

Print a greeting to `name`.
"""
greet(name) = println("Hello, ", name)
```

```?help-example
greet
```

## Package mode

```]pkg-example
status
```

## Shell mode

```;shell-example
echo hello from the shell
printf 'two\nlines\n'
```

Shell and julia fences share the page's scratch working directory:

```;shell-write
echo scratch > created.txt
```

```>cwd-example
read("created.txt", String)
```

## Plain fences

```!plain-output
println("plain fence output")
```

```!hide-line
hidden_setup = 1  # hide
visible_line = hidden_setup + 1;
```

```!hidden
#hideall
hidden_value = 123
```

## Static REPL blocks

```julia-repl
julia> 1 + 1
2

(demo) pkg> st

infil> @locals

1|debug> n

1|julia> k
```

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

\toc

\activate{}

The end.
