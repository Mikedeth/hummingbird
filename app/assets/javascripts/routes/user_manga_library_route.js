HB.UserMangaLibraryRoute = Ember.Route.extend({
  model: function(params) {
    var user_id = this.modelFor('user').get('id');
    return this.store.find('mangaLibraryEntry', {
      user_id: user_id,
      status: "Currently Reading"
    });
  },

  setupController: function(controller, model) {
    var user_id = this.modelFor('user').get('id');
    controller.set('model', model);
    controller.set('loadingRemaining', true);
    return this.store.find('mangaLibraryEntry', {
      user_id: user_id
    }).then(function(entries) {
      controller.get('content').addObjects(entries.filter(function(l) {
        return l.get('status') !== "Currently Reading";
      }));
      return controller.set('loadingRemaining', false);
    });
  },

  deactivate: function() {
    return this.controllerFor('user.library').set('model', []);
  },

  afterModel: function() {
    return HB.TitleManager.setTitle(this.modelFor('user').get('id') + "'s Library");
  }
});
