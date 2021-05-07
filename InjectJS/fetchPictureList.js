
function getPictureList() {
    // var obj = document.getElementsByClassName('article-content')[0].getElementsByTagName('img');
    var obj=document.getElementsByTagName('img');
    var strImg = "文章所有图片：";
    var imageArray = [];
    for (var i=0; i<obj.length; i++) {
        var imgSrc = obj[i].getAttribute('src');
        if (imgSrc) {
            obj[i].id = i;
            obj[i].onclick = function() {
                window.webkit.messageHandlers.callbackShowPicture.postMessage(this.getAttribute('id'));
            };
            imageArray.push(imgSrc);
            strImg = strImg + "\r\n" + imgSrc;
        }
    }
    document.getElementById('textarea1').value = strImg;
    window.webkit.messageHandlers.callbackPictureList.postMessage(imageArray);
}

//function getImages(){
//    var objs = document.getElementsByTagName('img');
//    var imgScr = [];
//    for(var i=0;i<objs.length;i++){
//        imgScr.push(objs[i])
//        // imgScr = imgScr + objs[i].src + '+';
//
//        objs[i].onclick=function(){
//            document.location="myweb:imageClick:"+this.src;
//        };
//
//    };
//    return imgScr;
//};
