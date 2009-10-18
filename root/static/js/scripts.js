function cut(id) {
    document.cookie = 'id=' + id + '; path=/'
    return;
}

function paste(link, after) {
    id = document.cookie.match(/\bid=\d+/);
    location.href = link.href + ';' + id + ';after=' + after;
    return false;
}
