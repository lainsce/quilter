if(o==="}"){a--}n++};
return-1};var a=function(e,t,r,a){var i=[];for(var o=0;o<e.length;o++){if(e[o].type==="text"){var l=e[o].data;var f=!0;var d=0;var s;s=l.indexOf(t);if(s!==-1){d=s;i.push({type:"text",data:l.slice(0,d)});f=!1}
while(!0){if(f){s=l.indexOf(t,d);if(s===-1){break}
i.push({type:"text",data:l.slice(d,s)});d=s}else{s=n(r,l,d+t.length);if(s===-1){break}
i.push({type:"math",data:l.slice(d+t.length,s),rawData:l.slice(d,s+r.length),display:a});d=s+r.length}f=!f}
i.push({type:"text",data:l.slice(d)})}else{i.push(e[o])}}return i};t.exports=a},{}]},{},[1])(1)})