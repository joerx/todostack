(function() {

    var todoListRoot = document.getElementById('todo-list');
    var todoForm = document.getElementById('todo-form');
    var inputField = document.getElementById('todo-form-entry');

    if (!todoListRoot) {
        throw Error('Root node not found');
    }

    if (!todoForm) {
        throw Error('Form node not found');
    }

    if (!inputField) {
        throw Error('TODO input field not found');
    }

    /**
     * Fetch data from given URL, decode as JSON, resolve as Promose. Reject an error if backend 
     * responds any status code greater or equals 400. Error will have message sent by backend.
     * 
     * This function uses the fetch API and is thus not save to use in older browsers. 
     *
     * We could be a little bit sad about that, but we aren't.
     * 
     * @param {*} url 
     */
    var fetchData = function(url, options) {
        var headers = new Headers();
        headers.append('Content-type', 'application/json');

        var defaults = {headers: headers, method: 'GET'};
        var realOptions = Object.assign({}, defaults, options);

        return fetch(url, realOptions)
            .then(function(res) {
                return Promise.all([res.status, res.json()]);
            })
            .then(function(arr) {
                const status = arr[0];
                const data = arr[1];
                if (status < 400) return data;
                else return Promise.reject(Error(data.message || 'Unknown error'));
            });
    }

    var makeTodoItem = function(todo) {
        var liNode = document.createElement('li');
        liNode.textContent = todo.item;
        liNode.setAttribute('data-id', todo._id);
        return liNode;
    }

    var postTodoItem = function(item) {
        console.log('new todo item', item);

        var body = JSON.stringify({item: item});
        var options = {method: 'POST', body: body};

        fetchData('/api/todos', options)
            .then(function(responseData) {
                inputField.value = '';
                inputField.focus();
                updateTodoList();
            });
    }

    todoForm.addEventListener('submit', function(e) {
        e.preventDefault();
        var entry = inputField.value;
        postTodoItem(entry);
    });

    window.updateTodoList = function() {
        fetchData('/api/todos')
            .then(function(data) {
                todoListRoot.innerHTML = '';
                data.forEach(function(entry) {
                    todoListRoot.appendChild(makeTodoItem(entry));
                });
            })
            .catch(function(err) {
                console.error(err);
            });
    }

    updateTodoList();

})();
