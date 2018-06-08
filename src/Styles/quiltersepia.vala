/*
The MIT License (MIT)

Copyright (c) 2017 Lains

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

public class Quilter.Styles.quiltersepia {
  public const string css="""
    html {
      font-size: 16px;
    }

    p {
      font-size: 18px;
      color: #3b3228;
    }

    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
    }

    h1:first-of-type,
    h2:first-of-type,
    h3:first-of-type,
    h4:first-of-type,
    h5:first-of-type,
    h6:first-of-type {
      margin-top: 20px;
    }

    h1 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: 2rem;
      text-align: center;
      text-transform: uppercase;
    }

    h2 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: 1.5rem;
      text-align: center;
      text-transform: uppercase;
    }

    h3 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: 1.25rem;
      text-align: center;
      text-transform: uppercase;
    }

    h4 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: 1rem;
      text-align: center;
    }

    h5 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: .875rem;
      text-align: center;
    }

    h6 {
      margin-top: 1em;
      margin-bottom: 1em;
      font-size: .75rem;
    }

    small {
      font-size: .7em;
    }

    img,
    canvas,
    iframe,
    video,
    select,
    textarea {
      display: block;
      max-width: 50%;
    }

    body {
      color: #3b3228;
      background-color: #F0E8DD;
      font-family: 'Tinos', serif;
      font-weight: 400;
      line-height: 1.4rem;
      margin-left: 80px;
      margin-right: 80px;
      align-content: center;
      align-items: center;
      align-self: center;
      display: inline-block;
      text-align: left;
    }

    table {
      border-spacing: 0;
      border-collapse: collapse;
      margin-top: 0;
      margin-bottom: 16px;
    }

    table th {
      font-weight: bold;
      background-color: #e0d0b9;
    }

    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #e0d0b9;
    }

    table tr {
      border-top: 1px solid #e0d0b9;
    }

    img {
      border-radius: .5rem;
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

    code{
      display: inline-block;
      padding: 0 0.25rem;
      background-color: #e0d0b9;
      border: 1px solid #e0d0b9;
      border-radius: 4px;
      font-family: 'Quilt Mono', monospace;
      font-weight: normal;
    }

    pre code{
      display: block;
      margin: 1rem auto;
      overflow-x: scroll;
      padding: 0.5em;
    }

    blockquote {
      margin: 0;
      border-left: 5px solid #7e6e62;
      font-style: italic;
      padding-left: .8rem;
      margin-left: .8rem;
      text-align: left;
    }
    
    blockquote > p {
      color: inherit;
      margin-top: 20px;
      margin-bottom: 20px;
      padding-top: 20px;
      padding-bottom: 20px;
    }

    ul {
      list-style: disc;
    }

    ul>li {
      font-size: 18px;
    }
  
    ul, ol {
      margin-left: -40px;
    }

    hr {
      overflow: visible;
      padding: 0;
      border: none;
      color: inherit;
      text-align: center;
    }
    hr:after {
      content: "...";
      letter-spacing: .6em;
      display: inline-block;
      position: relative;
      top: -0.3rem;
      font-size: 1.65em;
      padding: 0 0.25em;
      background: inherit;
    }
  """;
}
