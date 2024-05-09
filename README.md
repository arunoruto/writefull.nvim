# Writefull.nvim

I recently stumbled upon writefull, an amazing tool to aid you in your academic writing. It has plugins for overleaf and word, but lacks one for nvim or vscode. Since I have never written a plugin for (neo)vim before, I will take this as a chance to learn it a bit!

This repo will be used to gather information and ideas, before I have time to implement this!

# API

I am using the writefull integration into overleaf and analyzed the network a bit. So, what is needed to communicate with writefull?
| Key | Value |
| --- | ----- |
| URL | https://nlp.writefull.ai/prompt |
| Firebase Token | \<a long, long string\> |
| Content type | application/json |
| Data to be analyzed | Context and selected string |

The data to be passed on has the following structure:
An example for how data is passed is given by: [(the text originates from Bridsons algorithm)](https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf)

```json
{
  "action": "rewrite_paraphrase",
  "context": "Blue noise sample patterns — for example produced by Poisson disk distributions, where all samples are at least distance r apart for some user-supplied density parameter $r$ — are generally considered ideal for many applications in rendering (see Cook’s landmark paper for example [1986]). Unfortunately, the naive rejection-based approach for generating Poisson disk samples, dart throwing, is impractically inefficient.",
  "selection": {
    "start": 29,
    "end": 173
  }
}
```

This means the request takes the content of the whole document as a context and start and end mark what part of the string is selected and needs to be rephrased.
The server responded with:

```json
{
  "result": [
    {
      "type": "text",
      "value": "such as those generated through Poisson disk distributions, in which each sample maintains a minimum separation of $r$, determined by a specified density parameter $r$",
      "deltas": [
        {
          "type": "removed",
          "value": "for  example  produced  by"
        },
        {
          "type": "added",
          "value": "such  as  those  generated  through"
        },
        {
          "type": "unchanged",
          "value": " Poisson  disk  distributions,"
        },
        {
          "type": "removed",
          "value": " where  all  samples  are  at  least  distance  r  apart  for  some  user-supplied"
        },
        {
          "type": "added",
          "value": " in  which  each  sample  maintains  a  minimum  separation  of  $r$,  determined  by  a  specified"
        },
        {
          "type": "unchanged",
          "value": " density  parameter  $r$"
        }
      ]
    }
  ],
  "replacement_indices": {
    "start": 29,
    "end": 173
  },
  "ok": true
}
```

The response doesn't give the string directly but instructions on how to "build it". This information can be used to display the changes which are about to be made in a small diff window.

# Implementation

## Rephrase

My current idea is to make writefull available when being in visual mode. One would select some coherent part of the text, execute a command/shortcut (like \<(local)leader\> (w)ritefull (r)ephrease) and a request is being made to https://nlp.writefull.ai/prompt with the data correctly set. The retrieved response would be displayed in a small window (some kind of diff preview) and the user can press _y_ to accept the changes, _n_ to reject it, _r_ to retry it and get a new response, and _t_ to toggle between diff (see all changes like in overleaf) and result (just the resulting text) preview.

## Auth

For now, writefull has no official API documentation. But the Firebase Token can be used to make queries and the token can be provided using a command like `:writefull (firebase-)token <token>`. I will see how often this token changes. If it isn't renewed that often, one can manually always provide it, until we get an official API on how to do this!

# Development

Most of these things may seem trivial for you, but I am still learning and I need a place to put all my thoughts down.

## Use plugin locally

We need to adjust the runtime path to include the local directory. The root of this repository has to be included:

```sh
nvim --cmd "set rtp+=./"
```
