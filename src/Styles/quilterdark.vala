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

public class Quilter.Styles.quilterdark {
  public const string css="""
    html {
      font-size: 1rem;
      width: 100%;
      margin: 0 auto;
    }

    p {
      font-size: 1.1rem;
      line-height: 1.66rem;
      width: 100%;
      color: #C3C3C1;
    }

    h1,
    h2,
    h3,
    h4,
    h5,
    h6 {
      font-style: bold;
      margin-top: 2rem;
    }

    h1 {
      font-size: 2rem;
      text-align: center;
      text-transform: uppercase;
    }

    h2 {
      font-size: 1.5rem;
      text-transform: uppercase;
    }

    h3 {
      font-size: 1.25rem;
    }

    h4 {
      font-size: 1.125rem;
    }

    h5 {
      font-size: 1.1rem;
    }

    h6 {
      font-size: 1rem;
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
      color: #C3C3C3;
      background-color: #111111;
      font-weight: 400;
      line-height: 1.4rem;
      margin-left: 40px;
      margin-right: 40px;
      margin-top: 40px;
      margin-bottom: 40px;
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
      background-color: #2b2b2b;
    }

    table th,
    table td {
      padding: 8px 13px;
      border: 1px solid #2b2b2b;
    }

    table tr {
      border-top: 1px solid #2b2b2b;
    }

    img {
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
      background-color: #23241c;
      border: 1px solid #23241c;
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
      border-left: 5px solid #7E8087;
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
