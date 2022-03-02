# Azigmetic

A command-line math utility, written in Zig.

## Features
### ADVANCED, FULL-SPECTRUM PEMDAS SUPPORT!

- *P*arentheses `()`
- *E*xponentiation `^`
- *M*ultiplication `*`
- *D*ivision `/`
- *A*ddition `+`
- *S*ubtraction `-`

### VARIABLES!

- Assignment: `foo = 5`
- Usage: `foo * 2`
- List: `variables`
```
foo = 5
(= foo 5) = 5

foo * 2
(* foo 2) = 10

variables
foo: 5
```

### RESULTS!

- The result of each successfully-evaluated expression is stored as a `$`-prefixed numbered constant.
- Usage: `$1 * 28`
- List: `results`
```
5 * 2
(* 5 2) = 10

results
$1: 10

$1 * 28
(* $1 28) = 280
```

### BONUS OPERATORS!

- Factorial `!`
- Modulo `%`

### COMING SOON!

- Roots
