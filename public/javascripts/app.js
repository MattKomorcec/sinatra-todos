$(function () {
    $("form.delete").submit(function (event) {
        event.preventDefault()
        event.stopPropagation()

        const ok = confirm("Are you sure? This cannot be undone!")

        if (ok) {
            const form = $(this)

            const request = $.ajax({
                url: form.attr("action"),
                method: form.attr("method")
            })

            request.done(function (data, textStatus, jqXhr) {
                if (jqXhr.status === 204) {
                    form.parent("li").remove()
                } else if (jqXhr.status === 200) {
                    document.location = data
                }
            })
        }
    })
})