/*
The MIT License (MIT)

Copyright (c) 2014-2015 John Otander

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

public class Quilter.Styles.quilterdark {
  public const string css = """
html {
font-size: 16px;
}

body {
line-height: 1.5;
}

p,
.air-p {
font-size: 1rem;
}

h1,
.air-h1,
h2,
.air-h2,
h3,
.air-h3,
h4,
.air-h4 {
margin: 1.214rem 0 .5rem;
font-weight: inherit;
}

h1,
.air-h1 {
margin-top: 0;
font-size: 3rem;
}

h2,
.air-h2 {
font-size: 2rem;
}

h3,
.air-h3 {
font-size: 1.5rem;
}

h4,
.air-h4 {
font-size: 1.214rem;
}

h5,
.air-h5 {
font-size: 1.121rem;
}

h6,
.air-h6 {
font-size: .88rem;
}

small,
.air-small {
font-size: .707em;
}

/* https://github.com/mrmrs/fluidity */

img,
canvas,
iframe,
video,
svg,
select,
textarea {
display: block;
max-width: 40%;
}

body {
color: #eff0f1;
background-color: #232629;
font-family: 'Open Sans', Helvetica, sans-serif;
font-weight: 400;
margin-left: 80px;
margin-right: 80px;
margin-top: 40px;
max-width: 50rem;
text-align: left;
}

img {
border-radius: 10%;
height: auto;
margin: 0 auto;
}

a,
a:visited,
a:hover,
a:focus,
a:active {
color: #1d99f3;
}

pre {
font-family: 'PT Mono', monospace;
background-color: #4D4D4D;
color: #7E8087;
padding: 1rem;
text-align: left;
}

blockquote {
margin: 0;
border-left: 5px solid #1d99f3;
font-style: italic;
padding-left: .8rem;
text-align: left;
}

ul,
ol,
li {
text-align: left;
}

p {
color: #eff0f1;
}""";
}